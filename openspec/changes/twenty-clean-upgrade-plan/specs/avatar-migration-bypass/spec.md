# Spec: Avatar Migration Bypass

## ADDED: Clear broken avatar URLs before v1.18.1 upgrade

The `MigratePersonAvatarFilesCommand` at v1.18.1 iterates over all person records with `avatarUrl ILIKE '%people%'` and attempts to copy each file from old storage to new storage. If any file is missing on S3/disk, the command throws a fatal error and aborts the entire upgrade. This pre-fix NULLs out avatar URLs for records with broken S3 references so the migration has nothing to process.

### Requirement: Clear avatarUrl for persons with avatar references

The fix must be applied inside the previous version's container (v1.17.0) using TypeORM's `connectionSource`.

#### Scenario: Avatar URLs are cleared before v1.18.1 upgrade

WHEN the `twenty` container is running v1.17.0
AND a node one-liner is executed via `docker exec twenty node -e "..."`
AND it queries `core.workspace` to find the workspace schema name
AND it runs `UPDATE "<schema>".person SET "avatarUrl" = NULL WHERE "avatarUrl" ILIKE '%people%'`
THEN all person records with avatar URL references are updated to have NULL avatarUrl
AND the script logs the number of affected rows

#### Scenario: No person records have avatar URLs

WHEN the UPDATE query matches 0 rows
THEN the script completes without error
AND the upgrade proceeds normally (the `MigratePersonAvatarFilesCommand` finds 0 records to migrate)

### Requirement: Only cosmetic data is affected

#### Scenario: Avatar clearing does not affect business data

WHEN avatarUrl values are set to NULL
THEN only the person profile picture reference is removed
AND no other person fields (name, email, phone, company relations, etc.) are modified
AND users can re-upload avatars after the upgrade completes

#### Scenario: Broken S3 references produce no worse outcome

WHEN a person's avatarUrl pointed to a non-existent S3 file
THEN the avatar was already not rendering in the UI before the fix
AND NULLing the URL does not cause additional data loss

### Requirement: Fix runs before the container is upgraded

The pre-fix must be applied while the v1.17.0 container is still running.

#### Scenario: Correct execution order

WHEN the operator is at the v1.17.0 step
THEN the operator runs the node one-liner avatar cleanup script
AND verifies the output shows the number of cleared URLs
AND only then changes `version = "v1.18.1"` in `twenty.nix`
AND runs `sudo nixos-rebuild switch --flake .#technative-casper`
AND the `MigratePersonAvatarFilesCommand` succeeds with 0 files to migrate
