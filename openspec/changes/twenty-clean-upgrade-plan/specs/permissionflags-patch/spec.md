# Spec: permissionFlags JS Patch

## ADDED: Compiled JS patch for permissionFlags bug at v1.7.10, v1.8.15, v1.11.14

Patches the `WorkspaceSyncRoleService` and `fromStandardRoleDefinitionToFlatRole` utility inside the running container to apply the same fix as upstream PR #16459. This allows the workspace metadata sync to complete successfully at versions where the bug exists (all versions before v1.12.17).

### Requirement: Patch fromStandardRoleDefinitionToFlatRole to exclude permissionFlags

The `fromStandardRoleDefinitionToFlatRole` function spreads the entire `StandardRoleDefinition` object (including the `permissionFlags` array) into a `FlatRole`. When TypeORM later tries to `.update()` the role, it encounters the relation property and fails with "Cannot query across one-to-many for property permissionFlags".

The patch must destructure away `permissionFlags` before spreading.

#### Scenario: Workspace sync succeeds after patching fromStandardRoleDefinitionToFlatRole

WHEN the compiled JS file `from-standard-role-definition-to-flat-role.util.js` is patched to destructure away `permissionFlags` before spreading the standard role definition
THEN the `fromStandardRoleDefinitionToFlatRole` function returns a `FlatRole` object without `permissionFlags`
AND the workspace sync role comparator does not trigger a TypeORM update with relation properties

#### Scenario: Patch targets the correct file path in each version

WHEN applying the patch at v1.7.10, v1.8.15, or v1.11.14
THEN the file is located at `/app/packages/twenty-server/dist/engine/workspace-manager/workspace-sync-metadata/services/utils/from-standard-role-definition-to-flat-role.util.js` (or similar, depending on the compiled output structure)
AND the patch is verified by inspecting the file content after applying

### Requirement: Strip relation ID properties from removePropertiesFromRecord calls

The `workspace-sync-role.service.js` file has two `removePropertiesFromRecord` calls (CREATE and UPDATE paths) that must also strip `permissionFlagIds`, `fieldPermissionIds`, `objectPermissionIds`, and `roleTargetIds`. Without this, TypeORM attempts to set virtual relation-derived columns that don't exist on the `role` table.

#### Scenario: CREATE path strips relation ID properties

WHEN a new standard role is being created during workspace sync
THEN the `removePropertiesFromRecord` call in the CREATE path includes `permissionFlagIds`, `fieldPermissionIds`, `objectPermissionIds`, `roleTargetIds` in its exclusion list
AND the resulting INSERT does not reference any relation-derived columns

#### Scenario: UPDATE path strips relation ID properties

WHEN an existing standard role is being updated during workspace sync
THEN the `removePropertiesFromRecord` call in the UPDATE path includes `permissionFlagIds`, `fieldPermissionIds`, `objectPermissionIds`, `roleTargetIds` in its exclusion list
AND the resulting UPDATE does not reference any relation-derived columns

### Requirement: Patch is applied with DISABLE_DB_MIGRATIONS, then upgrade is run manually

Since `nixos-rebuild switch` starts containers immediately and there is no NixOS option to prevent auto-start, the `twenty` server must be started with `DISABLE_DB_MIGRATIONS=true` so it skips the upgrade on startup. The JS files are then patched, and the upgrade is triggered manually via `docker exec`. This avoids restarting the container (which would reset the filesystem to the unpatched image state).

#### Scenario: Disable migrations, patch, then run upgrade manually

WHEN the operator temporarily adds `DISABLE_DB_MIGRATIONS = "true"` to the `twenty` server environment in `twenty.nix`
AND sets the version to v1.7.10 (or v1.8.15 / v1.11.14)
AND runs `sudo nixos-rebuild switch --flake .#technative-casper`
THEN the `twenty` container starts without running migrations
AND the operator applies the JS patches via `docker exec twenty sed ...`
AND the operator runs `docker exec twenty sh -c 'yarn command:prod cache:flush && yarn command:prod upgrade && yarn command:prod cache:flush'`
AND the workspace sync completes successfully with the patched code
AND the workspace version is bumped automatically

#### Scenario: DISABLE_DB_MIGRATIONS is removed after successful upgrade

WHEN the upgrade at v1.7.10 (or v1.8.15 / v1.11.14) completes successfully
THEN the operator removes `DISABLE_DB_MIGRATIONS = "true"` from the `twenty` server environment in `twenty.nix`
AND the `twenty` server resumes running migrations on startup for subsequent version steps (v1.10.8, v1.12.18, etc.)

### Requirement: Patch must be version-specific

The compiled JS output structure may differ between v1.7.10, v1.8.15, and v1.11.14. The patch (sed patterns or script) must be crafted per version by inspecting the actual compiled files.

#### Scenario: Pre-inspection of compiled files

WHEN preparing for the upgrade
THEN each affected Docker image is pulled and the target JS files are extracted via `docker create` + `docker cp`
AND the exact function signatures and variable names are identified
AND version-specific sed commands are prepared and tested
