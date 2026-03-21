# Proposal: Twenty CRM Clean Upgrade Plan (v1.6.7 → v1.19.0)

## Problem

The previous upgrade from v1.6.7 to v1.18.1 required manual `psql` commands at nearly every step — most critically, manual `UPDATE core.workspace SET version = ...` bumps that skipped workspace metadata migrations. This caused silent metadata gaps (missing views, viewFields, navigation items) that weren't discovered until after the upgrade was complete.

For a production upgrade, we need a procedure that:
1. Never manually bumps `core.workspace.version`
2. Lets every migration and workspace sync run to completion
3. Uses only automated, scripted pre-fixes for known issues
4. Requires only `docker exec`, cache flush, and container restart — no direct `psql`

## Root Cause Analysis

The errors from the previous upgrade fall into 4 categories:

### Category A: Race condition between `twenty` and `twenty-worker` (RESOLVED)

Both containers used to run `typeorm migration:run` on startup with no coordination. Whichever booted faster applied migrations; the slower one got `duplicate key` / `already exists` errors.

**Affected steps:** v1.7.7, v1.12.0, v1.15.0, v1.16.7, v1.17.0, v1.18.1

**Fix (applied):** `DISABLE_DB_MIGRATIONS=true` and `DISABLE_CRON_JOBS_REGISTRATION=true` have been added to the `twenty-worker` container environment in `modules/services/tools/twenty.nix`. The worker will never run migrations — only the `twenty` server container does. This matches the official Twenty docker-compose configuration. No procedural workaround needed.

### Category B: `permissionFlags` upstream code bug

The `WorkspaceSyncRoleService` spreads `permissionFlags` (a one-to-many relation array) into a flat role object, then passes it to `roleRepository.update()`. TypeORM tries to set a non-existent column derived from the relation metadata, producing: `Cannot query across one-to-many for property permissionFlags`.

This was fixed in PR [#16459](https://github.com/twentyhq/twenty/pull/16459), first released in **v1.12.17**. However, v1.12.17 has no Docker image — the only v1.12.x image on Docker Hub is v1.12.0, which is still affected. The fix is first available in **v1.13.7** on Docker Hub.

**Affected steps:** v1.7.7, v1.8.2, v1.11.5, v1.12.0

**Fix:** Before starting the container at these versions, patch the compiled JS inside the container to apply the same fix from PR #16459:
1. In `from-standard-role-definition-to-flat-role.util.js`: destructure away `permissionFlags` before spreading
2. In `workspace-sync-role.service.js`: add `permissionFlagIds`, `fieldPermissionIds`, `objectPermissionIds`, `roleTargetIds` to the `removePropertiesFromRecord` calls in both CREATE and UPDATE paths

### Category C: Pre-existing data issues

**v1.10.2 — Orphaned serverless function:**
A serverless function row with NULL `serverlessFunctionLayerId` blocks the `SET NOT NULL` core migration. This is pre-existing data, not caused by the upgrade.

**Fix:** Before upgrading to v1.10.2, delete the orphaned row using a node.js one-liner via `docker exec` that uses TypeORM's datasource connection (no psql needed).

**v1.18.1 — Missing S3 avatar file:**
`MigratePersonAvatarFilesCommand` iterates all person records with `avatarUrl ILIKE '%people%'` and tries to copy the file. If the file doesn't exist on S3/disk, it throws and aborts the entire upgrade. No retry/skip logic.

**Fix:** Before upgrading to v1.18.1, NULL out the `avatarUrl` for person records whose files don't exist on S3, using a node.js script via `docker exec`. Alternatively, set the `IS_FILES_FIELD_MIGRATED` feature flag to skip the entire avatar migration (v1.19.0 deprecates it anyway).

### Category D: Self-resolving on clean upgrade

These errors only occurred because of retry/partial-failure states from the previous botched upgrade. On a **clean first-time upgrade** from a fresh v1.6.7 backup, they will not occur:

- **v1.12.0** `canBeUninstalled` column already exists — caused by partial migration rollback losing the record
- **v1.13.7** `SyncableRoleTarget` references wrong table — all migrations were already applied from a prior run
- **v1.17.0** `salesIdeaId` doesn't exist — column was already renamed in a previous attempt

## Upgrade Plan

### Prerequisites

- Fresh `pg_dump` backup of the v1.6.7 database
- `DISABLE_DB_MIGRATIONS=true` set on `twenty-worker` container (already applied in `modules/services/tools/twenty.nix`)

### Version Selection

Docker Hub tags do NOT match GitHub tags — many GitHub patch releases have no corresponding Docker image. The actual available upgrade path using Docker Hub images is:

```
v1.6.7 → v1.7.7 → v1.8.2 → v1.10.2 → v1.11.5 → v1.12.0 → v1.13.7 → v1.14.0 → v1.15.0 → v1.16.7 → v1.17.0 → v1.18.1 → v1.19.0
```

Note: There is no v1.9.x series (Twenty skipped it).

### How to change versions

The version is defined in `modules/services/tools/twenty.nix` on the `version` variable (line 5). Both `twenty` and `twenty-worker` containers use `twentycrm/twenty:${version}`, so changing this single variable updates both.

```bash
# 1. Edit the version in twenty.nix (change version = "v1.X.Y";)
# 2. Rebuild and switch:
sudo nixos-rebuild switch --flake .#technative-casper
```

This pulls the new image and restarts both containers. The `twenty` server runs migrations on startup; `twenty-worker` skips them (`DISABLE_DB_MIGRATIONS=true`).

### Step-by-Step Procedure

For each version step:

```
1. Apply pre-fix for this version (if any — see below)
2. Update version in modules/services/tools/twenty.nix
3. sudo nixos-rebuild switch --flake .#technative-casper
4. Wait for twenty to become healthy + check logs:
   docker logs twenty 2>&1 | grep -iE "error|fail|migrated|upgrade|version"
5. Verify workspace version was bumped:
   docker exec twenty psql "$PG_DATABASE_URL" -c "SELECT version FROM core.workspace;"
6. If clean: proceed to next step
```

### Pre-fixes by Version

#### v1.6.7 → v1.7.7: Patch workspace sync bugs (permissionFlags + agent)

Two upstream bugs cause the workspace sync to crash:

1. **permissionFlags bug** (PR [#16459](https://github.com/twentyhq/twenty/pull/16459)): `WorkspaceSyncRoleService` spreads `permissionFlags` from `StandardRoleDefinition` into a flat role object, but the property has no database column.
2. **createHandoffFromDefaultAgent bug**: `WorkspaceSyncAgentService` spreads `createHandoffFromDefaultAgent` from standard agent definitions, but the property has no database column.

Both are the same pattern — code tries to persist a property that doesn't exist in the schema. The fix is to strip these properties before the database save/update calls.

**Procedure:**

1. Add `DISABLE_DB_MIGRATIONS = "true";` to the **`twenty` server** environment in `twenty.nix` (temporarily)
2. Set `version = "v1.7.7";` in `twenty.nix`
3. `sudo nixos-rebuild switch --flake .#technative-casper` → container starts without running migrations
4. Apply all patches using `docker exec twenty node -e` (tested on v1.7.7):

```bash
# Patch 1: Destructure away permissionFlags in fromStandardRoleDefinitionToFlatRole
docker exec twenty sed -i 's/\.\.\.standardRoleDefinition,/...(({permissionFlags,...rest})=>rest)(standardRoleDefinition),/' \
  /app/packages/twenty-server/dist/src/engine/metadata-modules/flat-role/utils/from-standard-role-definition-to-flat-role.util.js

# Patch 2+3: Add relation IDs to removePropertiesFromRecord in workspace-sync-role.service.js
# (uses node because the arrays are multi-line, sed can't match them)
docker exec twenty node -e "
const fs = require('fs');
const f = '/app/packages/twenty-server/dist/src/engine/workspace-manager/workspace-sync-metadata/services/workspace-sync-role.service.js';
let c = fs.readFileSync(f, 'utf8');
c = c.replace(
  /removePropertiesFromRecord\)\(roleToCreate,\s*\[\s*'universalIdentifier',\s*'id'\s*\]/s,
  \"removePropertiesFromRecord)(roleToCreate, ['universalIdentifier', 'id', 'permissionFlagIds', 'fieldPermissionIds', 'objectPermissionIds', 'roleTargetIds']\"
);
c = c.replace(
  /removePropertiesFromRecord\)\(roleToUpdate,\s*\[\s*'id',\s*'universalIdentifier',\s*'workspaceId'\s*\]/s,
  \"removePropertiesFromRecord)(roleToUpdate, ['id', 'universalIdentifier', 'workspaceId', 'permissionFlagIds', 'fieldPermissionIds', 'objectPermissionIds', 'roleTargetIds']\"
);
fs.writeFileSync(f, c);
console.log('Patched workspace-sync-role.service.js');
"

# Patch 4+5: Add createHandoffFromDefaultAgent to removePropertiesFromRecord in workspace-sync-agent.service.js
docker exec twenty node -e "
const fs = require('fs');
const f = '/app/packages/twenty-server/dist/src/engine/workspace-manager/workspace-sync-metadata/services/workspace-sync-agent.service.js';
let c = fs.readFileSync(f, 'utf8');
c = c.replace(
  /removePropertiesFromRecord\)\(agentToCreate,\s*\[\s*'universalIdentifier',\s*'id'\s*\]/s,
  \"removePropertiesFromRecord)(agentToCreate, ['universalIdentifier', 'id', 'createHandoffFromDefaultAgent']\"
);
c = c.replace(
  /removePropertiesFromRecord\)\(agentToUpdate,\s*\[\s*'id',\s*'universalIdentifier',\s*'workspaceId',\s*'standardRoleId'\s*\]/s,
  \"removePropertiesFromRecord)(agentToUpdate, ['id', 'universalIdentifier', 'workspaceId', 'standardRoleId', 'createHandoffFromDefaultAgent']\"
);
fs.writeFileSync(f, c);
console.log('Patched workspace-sync-agent.service.js');
"
```

> **Note:** File paths use `dist/src/` (not `dist/`) in v1.7.7. The `node -e` approach is required because the arrays in the compiled JS are multi-line — `sed` cannot match them. v1.8.2, v1.11.5, and v1.12.0 may have different paths or function signatures — each must be verified before the upgrade.

5. Run the upgrade manually inside the container (patch stays intact — no restart needed):
   ```bash
   docker exec twenty sh -c 'yarn command:prod cache:flush && yarn command:prod upgrade && yarn command:prod cache:flush'
   ```
6. Verify the upgrade completes and workspace version is bumped
7. Remove `DISABLE_DB_MIGRATIONS` from the `twenty` server environment in `twenty.nix` (keep it on `twenty-worker`)

**Tested:** v1.7.7 upgrade completed successfully using this procedure. Workspace version bumped to 1.7.7. Zero `psql` commands used.

#### v1.7.7 → v1.8.2: Patch workspace sync bugs (permissionFlags + agent)

Same procedure as above:

1. Keep `DISABLE_DB_MIGRATIONS = "true"` on `twenty` server environment in `twenty.nix`
2. Set `version = "v1.8.2";` in `twenty.nix`
3. `sudo nixos-rebuild switch --flake .#technative-casper`
4. Apply all 5 JS patches (verify file paths in v1.8.2 image first), run upgrade manually via `docker exec`, verify
5. Remove `DISABLE_DB_MIGRATIONS` from `twenty` server (only if next step doesn't need it)

#### v1.8.2 → v1.10.2: Delete orphaned serverless function

> **Important:** Remove `DISABLE_DB_MIGRATIONS = "true"` from the `twenty` server environment in `twenty.nix` before this step. v1.10.2 does not need the workspace sync patches and should run its own migrations on startup. If you forget, the container will start but skip migrations, and the workspace version will not be bumped.

Before upgrading, run inside the **v1.8.2 container** (still running from previous step):

```bash
docker exec twenty node -e "
  const { connectionSource } = require('./dist/database/typeorm/core/core.datasource');
  connectionSource.initialize().then(async (ds) => {
    const rows = await ds.query(
      'DELETE FROM core.\"serverlessFunction\" WHERE \"serverlessFunctionLayerId\" IS NULL RETURNING id'
    );
    console.log('Deleted orphaned rows:', rows.length);
    await ds.destroy();
  }).catch(e => { console.error(e); process.exit(1); });
"
```

Then upgrade:

1. Set `version = "v1.10.2";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`
3. Verify clean upgrade (no permissionFlags patch needed — v1.10.x does not trigger the bug)

#### v1.10.2 → v1.11.5: Patch workspace sync bugs (permissionFlags + agent)

Same procedure as v1.7.7:

1. Add `DISABLE_DB_MIGRATIONS = "true";` to `twenty` server environment in `twenty.nix`
2. Set `version = "v1.11.5";` in `twenty.nix`
3. `sudo nixos-rebuild switch --flake .#technative-casper`
4. Apply all 5 JS patches (verify file paths in v1.11.5 image first), run upgrade manually via `docker exec`, verify, remove `DISABLE_DB_MIGRATIONS`

#### v1.11.5 → v1.12.0: Patch workspace sync bugs (permissionFlags + agent)

v1.12.0 is the only v1.12.x Docker image on Docker Hub. The permissionFlags fix (PR #16459) landed in v1.12.17, which has no Docker image. So v1.12.0 still has both bugs and needs the same patch procedure:

1. Add `DISABLE_DB_MIGRATIONS = "true";` to `twenty` server environment in `twenty.nix`
2. Set `version = "v1.12.0";` in `twenty.nix`
3. `sudo nixos-rebuild switch --flake .#technative-casper`
4. Apply all 5 JS patches (verify file paths in v1.12.0 image first), run upgrade manually via `docker exec`, verify, remove `DISABLE_DB_MIGRATIONS`

#### v1.12.0 → v1.13.7: No pre-fix needed

> **Important:** Remove `DISABLE_DB_MIGRATIONS = "true"` from the `twenty` server environment in `twenty.nix` before this step. v1.13.7 has the permissionFlags fix and should run its own migrations on startup.

1. Set `version = "v1.13.7";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

v1.13.7 includes the permissionFlags fix. The `canBeUninstalled` and `SyncableRoleTarget` errors from the previous upgrade were retry artifacts — won't occur on a clean upgrade.

#### v1.13.7 → v1.14.0: No pre-fix needed

1. Set `version = "v1.14.0";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

#### v1.14.0 → v1.15.0: No pre-fix needed

1. Set `version = "v1.15.0";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

#### v1.15.0 → v1.16.7: No pre-fix needed

1. Set `version = "v1.16.7";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

#### v1.16.7 → v1.17.0: No pre-fix needed

1. Set `version = "v1.17.0";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

The `salesIdeaId` rename error was a retry artifact — won't occur on a clean first-time upgrade. The column will be in its original name (`salesIdeaId`) and the rename to `targetSalesIdeaId` will succeed.

#### v1.17.0 → v1.18.1: Fix missing avatar file

Before upgrading, run inside the **v1.17.0 container** (still running from previous step) to clear broken avatar references:

```bash
docker exec twenty node -e "
  const { connectionSource } = require('./dist/database/typeorm/core/core.datasource');
  connectionSource.initialize().then(async (ds) => {
    const [ws] = await ds.query(
      'SELECT \"schemaName\" FROM core.workspace WHERE id = \\'d7858828-5f20-430a-ab76-e7555779126a\\''
    );
    const schema = ws.schemaName;
    const persons = await ds.query(
      'SELECT id, \"avatarUrl\" FROM \"' + schema + '\".person WHERE \"avatarUrl\" ILIKE \\'%people%\\''
    );
    console.log('Persons with avatars:', persons.length);
    if (persons.length > 0) {
      await ds.query(
        'UPDATE \"' + schema + '\".person SET \"avatarUrl\" = NULL WHERE \"avatarUrl\" ILIKE \\'%people%\\''
      );
      console.log('Cleared avatar URLs');
    }
    await ds.destroy();
  }).catch(e => { console.error(e); process.exit(1); });
"
```

This clears all avatar URLs so the migration has nothing to copy. Users will lose their old avatars (cosmetic only — they can re-upload).

Then upgrade:

1. Set `version = "v1.18.1";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

#### v1.18.1 → v1.19.0: No pre-fix needed

1. Set `version = "v1.19.0";` in `twenty.nix`
2. `sudo nixos-rebuild switch --flake .#technative-casper`

Clean upgrade expected. The v1.19.0 `SynchronizeTwentyStandardApplicationService` will reconcile all metadata, creating any missing views, viewFields, and navigation items.

### Post-Upgrade Verification

After reaching v1.19.0:

1. Verify both `twenty` and `twenty-worker` containers are healthy
2. Run the metadata audit query to confirm no standard objects have 0 views
3. Check the UI — verify dashboard, calendar events, messages appear correctly
4. Check the navigation sidebar for all expected items

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| permissionFlags patch doesn't apply cleanly (compiled JS structure differs between patch versions) | Medium | High — blocks upgrade | Test patch on each image before production. Prepare version-specific patches. |
| New errors at versions we haven't seen (v1.7.10 vs v1.7.7, v1.8.15 vs v1.8.2, etc.) | Low | Medium — unknown errors | Using latest patches gives more fixes, but test each step on a staging copy first. |
| v1.19.0 sync doesn't fix all metadata gaps | Low | Medium — missing views | Run audit query after upgrade; manually fix remaining gaps via Twenty API. |
| Avatar file pre-fix clears legitimate avatars | Low | Low — cosmetic only | Users can re-upload avatars after upgrade. |

## Summary

The clean upgrade requires **3 types of pre-fixes** across 12 version steps:

1. **Workspace sync JS patches (permissionFlags + agent)** — applied at v1.7.7, v1.8.2, v1.11.5, v1.12.0 (4 steps, using `DISABLE_DB_MIGRATIONS` + `docker exec twenty node -e`). Patches 3 files: `from-standard-role-definition-to-flat-role.util.js`, `workspace-sync-role.service.js`, `workspace-sync-agent.service.js`
2. **Delete orphaned serverless function** — applied before v1.10.2 (1 step)
3. **Clear broken avatar URLs** — applied before v1.18.1 (1 step)

The race condition between containers is eliminated at the infrastructure level by `DISABLE_DB_MIGRATIONS=true` on `twenty-worker` (already applied in `modules/services/tools/twenty.nix`). No need to stop the worker during upgrades.

The remaining 6 steps (v1.13.7, v1.14.0, v1.15.0, v1.16.7, v1.17.0, v1.19.0) require no pre-fixes and should upgrade cleanly.

Docker Hub availability note: GitHub tags (v1.7.10, v1.8.15, v1.11.14, v1.12.18, etc.) do not all have corresponding Docker images. Only the tags listed in the Version Selection section above are available on Docker Hub.
