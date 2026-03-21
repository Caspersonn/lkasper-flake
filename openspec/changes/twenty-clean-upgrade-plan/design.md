# Design: Twenty CRM Clean Upgrade Plan

## Context

Twenty CRM is deployed via OCI containers managed by NixOS (`modules/services/tools/twenty.nix`). The deployment consists of two containers — `twenty` (server) and `twenty-worker` — sharing the same Docker image (`twentycrm/twenty:${version}`), connected to a PostgreSQL database and Redis cache.

The workspace `d7858828-5f20-430a-ab76-e7555779126a` (TechNative) is currently on v1.19.0 after a manual upgrade from v1.6.7 that left metadata gaps. A clean re-upgrade from a fresh v1.6.7 backup is planned to ensure all migrations run fully.

The upgrade spans 12 sequential minor versions (v1.7 through v1.19) with 3 known blockers that require pre-fixes.

## Goals / Non-Goals

**Goals:**

- Execute all 12 upgrade steps with every migration and workspace metadata sync completing successfully
- Use only `docker exec` (node scripts, sed patches) and `nixos-rebuild switch` — no direct `psql`
- Never manually bump `core.workspace.version` — let Twenty's upgrade command handle it
- Produce a repeatable procedure that can be used for the production upgrade

**Non-Goals:**

- Fixing unrelated issues (Microsoft OAuth 401, S3 bucket misconfiguration)
- Upgrading beyond v1.19.0
- Modifying Twenty's source code or building custom Docker images
- Migrating to a different deployment tool (staying with NixOS OCI containers)

## Decisions

### 1. Disable migrations on the worker via environment variable

**Decision:** Set `DISABLE_DB_MIGRATIONS=true` on `twenty-worker` permanently in `twenty.nix`.

**Rationale:** Twenty's Docker entrypoint (`entrypoint.sh`) runs `yarn command:prod upgrade` before starting the actual process. Both containers share this entrypoint, so both attempt migrations unless explicitly disabled. The official `docker-compose.yml` already sets `DISABLE_DB_MIGRATIONS=true` on the worker — our NixOS config was missing this.

**Alternative considered:** Stopping the worker container before each upgrade step. Rejected because the env var is a permanent infrastructure fix, not a procedural workaround that could be forgotten.

### 2. Patch compiled JS for the permissionFlags bug using DISABLE_DB_MIGRATIONS + docker exec

**Decision:** For v1.7.10, v1.8.15, and v1.11.14, temporarily add `DISABLE_DB_MIGRATIONS=true` to the `twenty` server in `twenty.nix`, rebuild to start the container without running migrations, then patch the compiled JS via `docker exec` + `sed`, and finally run the upgrade manually via `docker exec twenty sh -c 'yarn command:prod upgrade'`.

**Rationale:** `nixos-rebuild switch` starts containers immediately — there is no way to prevent this with the NixOS oci-containers module. Disabling migrations on the server temporarily allows the container to start cleanly, giving us a window to patch the JS files before triggering the upgrade. Running the upgrade via `docker exec` keeps the patched files intact (no container restart that would reset the filesystem to the image state). After the upgrade succeeds, `DISABLE_DB_MIGRATIONS` is removed from the server for the next version step.

**Alternative considered:** Patching then restarting the container. Rejected because `nixos-rebuild switch` (or `docker restart`) recreates the container from the image, losing any filesystem patches applied via `docker exec`.

**Alternative considered:** Building custom Docker images with the fix baked in. Rejected because it adds significant complexity (Docker registry, build pipeline, image maintenance) for a one-time upgrade. The `DISABLE_DB_MIGRATIONS` + manual upgrade approach is simpler and achieves the same result.

**Alternative considered:** Skipping workspace sync at affected versions and relying on v1.19.0 to reconcile. Rejected because this is exactly what the previous upgrade did (via manual version bumps) and it caused the metadata gaps we're trying to avoid.

### 3. Delete orphaned data via node.js + TypeORM datasource, not psql

**Decision:** Use `docker exec twenty node -e "..."` scripts that import TypeORM's `connectionSource` to execute SQL.

**Rationale:** The constraint is "no direct psql commands" to avoid ad-hoc manual database manipulation. Using TypeORM's own datasource connection:
- Reuses the container's existing `PG_DATABASE_URL` environment variable
- Runs through the same connection pool configuration as Twenty itself
- Can be scripted and version-controlled
- Is semantically different from "open psql and type SQL" — it's a programmatic, targeted data fix

### 4. Clear avatar URLs instead of setting feature flag for v1.18.1

**Decision:** NULL out `avatarUrl` for person records with broken S3 references before upgrading to v1.18.1.

**Rationale:** The `MigratePersonAvatarFilesCommand` aborts on the first missing file with no skip logic. NULLing the URL removes the record from the migration query, so the command succeeds with 0 files to migrate. The alternative (setting `IS_FILES_FIELD_MIGRATED` feature flag) skips the entire migration, but could leave the `avatarFile` field metadata in an incomplete state.

**Trade-off:** Users whose avatars pointed to non-existent S3 files will lose their avatar reference. Since the files don't exist anyway, there's no actual data loss — just a cosmetic gap that users can fix by re-uploading.

### 5. Use latest patch versions instead of the exact versions from the previous upgrade

**Decision:** Use v1.7.10, v1.8.15, v1.10.8, v1.11.14, v1.12.18, v1.13.11, v1.16.16 instead of v1.7.7, v1.8.2, v1.10.2, v1.11.5, v1.12.0, v1.13.7, v1.16.7.

**Rationale:** Later patches contain bug fixes that may resolve issues we haven't yet encountered. The upgrade path is the same (sequential minors), just with more bug fixes at each step. The permissionFlags bug is NOT fixed in any v1.7.x, v1.8.x, or v1.11.x patch (only in v1.12.17+), so the JS patch is still needed for those 3 steps.

**Risk:** Untested patch versions could introduce new errors not seen in the previous upgrade. Mitigated by testing each step on the local `technative-casper` environment first.

## Risks / Trade-offs

**[permissionFlags JS patch may not apply cleanly]** → The compiled JS structure may differ between patch versions (v1.7.10 vs v1.7.7). The `sed` patterns are illustrative, not production-ready. Mitigation: before the upgrade, pull each affected image and inspect the actual compiled files to craft version-specific patches. Test each patch in isolation.

**[Unknown errors at untested patch versions]** → Using v1.7.10 instead of v1.7.7 could surface different errors. Mitigation: the local `technative-casper` environment serves as the test bed. Any new errors discovered during testing will be added to the procedure.

**[Workspace metadata sync may still fail at some steps]** → Even with the permissionFlags fix patched, other workspace sync issues could arise. Mitigation: v1.19.0's `SynchronizeTwentyStandardApplicationService` will reconcile all metadata at the end. If individual steps have sync issues, they'll be caught in the final audit.

**[Pre-fix scripts depend on container internals]** → The `require('./dist/database/typeorm/core/core.datasource')` path and `connectionSource` export may change between versions. Mitigation: verify the import path works on the target version's container before executing the data fix.

## Migration Plan

### Rollback Strategy

Before starting the upgrade, take a full `pg_dump`. If any step produces unrecoverable errors:

1. Restore the database from the backup
2. Reset the version in `twenty.nix` to `v1.6.7`
3. `sudo nixos-rebuild switch --flake .#technative-casper`

Each intermediate step can also be backed up if desired, creating restore points at each minor version.

### Deployment Order

1. Test the full 12-step procedure on `technative-casper` (local workstation)
2. Document any deviations or new errors discovered during testing
3. Apply the same procedure to production, using the tested and validated script

## Open Questions

1. **Exact sed patterns for permissionFlags patch**: The compiled JS in v1.7.10, v1.8.15, and v1.11.14 hasn't been inspected yet. The patches need to be crafted against the actual file content. Can the files be inspected by pulling the images and running `docker create` + `docker cp`?

2. **Are there new errors at the latest patch versions?**: v1.7.10, v1.8.15, v1.10.8, etc. haven't been tested. The previous upgrade used v1.7.7, v1.8.2, v1.10.2. The procedure should be validated end-to-end before production.

3. **S3 bucket configuration**: The previous upgrade surfaced an S3 misconfiguration (`twenty-test-bucket` vs production bucket). Should this be fixed before or after the upgrade? It affects whether avatar files exist on S3 for the v1.18.1 migration.
