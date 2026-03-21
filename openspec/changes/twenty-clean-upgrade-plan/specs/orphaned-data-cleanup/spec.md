# Spec: Orphaned Data Cleanup

## ADDED: Delete orphaned serverless function before v1.10.8 upgrade

Removes a serverless function row with a NULL `serverlessFunctionLayerId` from `core.serverlessFunction`. This row blocks the `SetServerlessFunctionLayerIdNotNullable1761153071116` TypeORM migration which adds a NOT NULL constraint to that column.

### Requirement: Delete orphaned serverless function rows via node.js

The deletion must be performed inside the previous version's container (v1.8.15) using TypeORM's `connectionSource` — not direct psql.

#### Scenario: Orphaned row is deleted before v1.10.8 upgrade

WHEN the `twenty` container is running v1.8.15 (the version before the upgrade to v1.10.8)
AND a node one-liner is executed via `docker exec twenty node -e "..."`
AND it imports `connectionSource` from `./dist/database/typeorm/core/core.datasource`
AND it runs `DELETE FROM core."serverlessFunction" WHERE "serverlessFunctionLayerId" IS NULL`
THEN the orphaned row is removed
AND the script logs the number of deleted rows

#### Scenario: No orphaned rows exist

WHEN the DELETE query matches 0 rows
THEN the script completes without error
AND logs "Deleted orphaned rows: 0"
AND the upgrade proceeds normally (the NOT NULL constraint succeeds because no NULLs exist)

### Requirement: Deletion does not affect valid serverless functions

#### Scenario: Only NULL-layerId rows are deleted

WHEN the DELETE query runs
THEN only rows where `serverlessFunctionLayerId IS NULL` are affected
AND rows with a valid `serverlessFunctionLayerId` (pointing to an existing layer) are not touched
AND no workspace functionality is impacted because the orphaned row pointed to a non-existent layer anyway

### Requirement: Deletion runs before the container is upgraded

The pre-fix must be applied while the v1.8.15 container is still running. The version in `twenty.nix` is only changed to v1.10.8 AFTER the deletion succeeds.

#### Scenario: Correct execution order

WHEN the operator is at the v1.8.15 step
THEN the operator runs the node one-liner cleanup script
AND verifies the output shows deletion succeeded
AND only then changes `version = "v1.10.8"` in `twenty.nix`
AND runs `sudo nixos-rebuild switch --flake .#technative-casper`
AND the `SetServerlessFunctionLayerIdNotNullable` migration succeeds
