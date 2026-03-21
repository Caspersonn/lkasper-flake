## 1. Preparation

- [ ] 1.1 Take a full `pg_dump` backup of the v1.6.7 database
- [ ] 1.2 Verify `DISABLE_DB_MIGRATIONS = "true"` and `DISABLE_CRON_JOBS_REGISTRATION = "true"` are set on `twenty-worker` in `modules/services/tools/twenty.nix`
- [ ] 1.3 Pull and inspect the compiled JS files for v1.7.10, v1.8.15, and v1.11.14 to craft version-specific `sed` patches for the permissionFlags bug (`docker create` + `docker cp` to extract files, identify exact function signatures)
- [ ] 1.4 Prepare and test the `sed` commands for each of the 3 affected versions against the extracted files

## 2. Upgrade v1.6.7 → v1.7.10 (permissionFlags patch)

- [ ] 2.1 Add `DISABLE_DB_MIGRATIONS = "true"` to the `twenty` server environment in `twenty.nix`
- [ ] 2.2 Set `version = "v1.7.10"` in `twenty.nix`
- [ ] 2.3 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 2.4 Apply the permissionFlags JS patch via `docker exec twenty sed ...`
- [ ] 2.5 Verify patch was applied by inspecting the patched files
- [ ] 2.6 Run `docker exec twenty sh -c 'yarn command:prod cache:flush && yarn command:prod upgrade && yarn command:prod cache:flush'`
- [ ] 2.7 Verify workspace version is `1.7.10` (or `1.7.0`): `docker exec twenty sh -c 'yarn command:prod version'` or query `core.workspace`
- [ ] 2.8 Remove `DISABLE_DB_MIGRATIONS` from the `twenty` server environment in `twenty.nix`

## 3. Upgrade v1.7.10 → v1.8.15 (permissionFlags patch)

- [ ] 3.1 Add `DISABLE_DB_MIGRATIONS = "true"` to the `twenty` server environment in `twenty.nix`
- [ ] 3.2 Set `version = "v1.8.15"` in `twenty.nix`
- [ ] 3.3 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 3.4 Apply the permissionFlags JS patch via `docker exec twenty sed ...`
- [ ] 3.5 Run `docker exec twenty sh -c 'yarn command:prod cache:flush && yarn command:prod upgrade && yarn command:prod cache:flush'`
- [ ] 3.6 Verify workspace version is bumped
- [ ] 3.7 Remove `DISABLE_DB_MIGRATIONS` from the `twenty` server environment in `twenty.nix`

## 4. Upgrade v1.8.15 → v1.10.8 (orphaned data cleanup)

- [ ] 4.1 Run the orphaned serverless function cleanup inside the v1.8.15 container: `docker exec twenty node -e "const{connectionSource}=require('./dist/database/typeorm/core/core.datasource');connectionSource.initialize().then(async ds=>{const r=await ds.query('DELETE FROM core.\"serverlessFunction\" WHERE \"serverlessFunctionLayerId\" IS NULL RETURNING id');console.log('Deleted:',r.length);await ds.destroy()}).catch(e=>{console.error(e);process.exit(1)})"`
- [ ] 4.2 Set `version = "v1.10.8"` in `twenty.nix`
- [ ] 4.3 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 4.4 Verify workspace version is bumped and no migration errors in logs

## 5. Upgrade v1.10.8 → v1.11.14 (permissionFlags patch)

- [ ] 5.1 Add `DISABLE_DB_MIGRATIONS = "true"` to the `twenty` server environment in `twenty.nix`
- [ ] 5.2 Set `version = "v1.11.14"` in `twenty.nix`
- [ ] 5.3 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 5.4 Apply the permissionFlags JS patch via `docker exec twenty sed ...`
- [ ] 5.5 Run `docker exec twenty sh -c 'yarn command:prod cache:flush && yarn command:prod upgrade && yarn command:prod cache:flush'`
- [ ] 5.6 Verify workspace version is bumped
- [ ] 5.7 Remove `DISABLE_DB_MIGRATIONS` from the `twenty` server environment in `twenty.nix`

## 6. Upgrade v1.11.14 → v1.12.18 (clean)

- [ ] 6.1 Set `version = "v1.12.18"` in `twenty.nix`
- [ ] 6.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 6.3 Verify workspace version is bumped and no errors in logs

## 7. Upgrade v1.12.18 → v1.13.11 (clean)

- [ ] 7.1 Set `version = "v1.13.11"` in `twenty.nix`
- [ ] 7.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 7.3 Verify workspace version is bumped and no errors in logs

## 8. Upgrade v1.13.11 → v1.14.0 (clean)

- [ ] 8.1 Set `version = "v1.14.0"` in `twenty.nix`
- [ ] 8.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 8.3 Verify workspace version is bumped and no errors in logs

## 9. Upgrade v1.14.0 → v1.15.0 (clean)

- [ ] 9.1 Set `version = "v1.15.0"` in `twenty.nix`
- [ ] 9.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 9.3 Verify workspace version is bumped and no errors in logs

## 10. Upgrade v1.15.0 → v1.16.16 (clean)

- [ ] 10.1 Set `version = "v1.16.16"` in `twenty.nix`
- [ ] 10.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 10.3 Verify workspace version is bumped and no errors in logs

## 11. Upgrade v1.16.16 → v1.17.0 (clean)

- [ ] 11.1 Set `version = "v1.17.0"` in `twenty.nix`
- [ ] 11.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 11.3 Verify workspace version is bumped and no errors in logs

## 12. Upgrade v1.17.0 → v1.18.1 (avatar migration bypass)

- [ ] 12.1 Run the avatar URL cleanup inside the v1.17.0 container: `docker exec twenty node -e "const{connectionSource}=require('./dist/database/typeorm/core/core.datasource');connectionSource.initialize().then(async ds=>{const[ws]=await ds.query('SELECT \"schemaName\" FROM core.workspace WHERE id=\\'d7858828-5f20-430a-ab76-e7555779126a\\'');const r=await ds.query('UPDATE \"'+ws.schemaName+'\".person SET \"avatarUrl\"=NULL WHERE \"avatarUrl\" ILIKE \\'%people%\\'');console.log('Cleared:',r[1],'avatars');await ds.destroy()}).catch(e=>{console.error(e);process.exit(1)})"`
- [ ] 12.2 Set `version = "v1.18.1"` in `twenty.nix`
- [ ] 12.3 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 12.4 Verify workspace version is bumped and no errors in logs

## 13. Upgrade v1.18.1 → v1.19.0 (clean)

- [ ] 13.1 Set `version = "v1.19.0"` in `twenty.nix`
- [ ] 13.2 Run `sudo nixos-rebuild switch --flake .#technative-casper`
- [ ] 13.3 Verify workspace version is `1.19.0`
- [ ] 13.4 Verify `SynchronizeTwentyStandardApplicationService` reports "Build succeeded / Run succeeded" in twenty logs

## 14. Post-Upgrade Verification

- [ ] 14.1 Verify both `twenty` and `twenty-worker` containers are healthy
- [ ] 14.2 Run metadata audit: confirm no active non-system objects have 0 views
- [ ] 14.3 Check the Twenty UI — verify `/objects/dashboards`, calendar events, messages render correctly
- [ ] 14.4 Check the navigation sidebar for all expected items (dashboards, companies, people, opportunities, tasks, notes, workflows)
- [ ] 14.5 Document any deviations or new errors discovered during testing
