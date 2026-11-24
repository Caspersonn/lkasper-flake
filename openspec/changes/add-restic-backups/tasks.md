# Tasks

## 1. Daily cleanup on kaito (separate deployment, first)

- [x] 1.1 Create `modules/nix/gc.nix` that exports `flake.modules.nixos.nix-gc`:
  - `nix.gc`: daily, `--delete-older-than 7d`, persistent, 45 min random delay
  - `nix.optimise`: automatic at 01:30
  - `docker-image-prune`: a oneshot service with a daily persistent timer that runs `docker image prune --force --filter until=168h`, inside `lib.mkIf config.virtualisation.docker.enable`

  `git add` the file. Verify that `nix flake check` passes.

  > Result: `nix flake check` passes for every configuration except `neko` and `server-casper`, which fail on the insecure `nextcloud-32.0.15` package. That failure is pre-existing and identical at `HEAD`, so this change did not cause it.
- [x] 1.2 Import `nix-gc` in `modules/hosts/kaito/configuration.nix`. Verify that `nix build .#nixosConfigurations.kaito.config.system.build.toplevel` succeeds and that `nix eval .#nixosConfigurations.kaito.config.systemd.timers --apply builtins.attrNames` includes `nix-gc`, `nix-optimise` and `docker-image-prune`.
- [x] 1.3 Verify the host-without-Docker scenario. Evaluate `nixosConfigurations.personal-casper.extendModules { modules = [ self.modules.nixos.nix-gc ]; }` and confirm that it builds and that `config.systemd.services ? docker-image-prune` is `false`.

  > Result: `docker-image-prune` service and timer both `false`, `nix.gc.automatic` `true`, and the toplevel `drvPath` evaluates. A full build was skipped because personal-casper's closure is not cached locally (314 derivations), so evaluation was used as the check.
- [x] 1.4 Record a baseline on kaito: `df -h /`, the number of system generations (`nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l`) and `docker system df`.

  > Baseline (2026-11-24):
  > - `df -h /`: 440G size, 342G used, 76G available (82%)
  > - 132 system generations (oldest 2026-04-18), 29 of them younger than 7 days
  > - `docker system df`: 20 images (6 active) at 11.37GB, 6.71GB reclaimable; 8/8 containers; 8 volumes at 302.8MB; no build cache
  > - networks: `bridge`, `host`, `none`, `solidtime-net`
- [ ] 1.5 Deploy kaito and run the first GC under supervision with `sudo systemctl start nix-gc.service`. Verify:
  - only generations from the last 7 days plus the current one remain
  - `df -h /` shows the reclaimed space

  Record the new free space.
- [ ] 1.6 Run `sudo systemctl start docker-image-prune.service`. Verify that all containers still run, `docker volume ls` is unchanged and `docker network ls` still lists `solidtime-net`, if Solidtime is deployed.

## 2. kaito audits (input for later tasks)

- [ ] 2.1 Run `sudo du -xsh /var/lib/* /var/lib/private/* | sort -h` on kaito and record the result in this change. The user decides what happens to the orphaned directories (`lidarr`, `jackett`, `nextcloud`, `*.legacy`, `zigbee2mqtt.backup.*`). List the extra state excludes for task 8.1.
- [x] 2.2 Verify that port 8100 is free (`ss -ltnp | grep ':8100'` returns nothing). Record the Nebula tun device name (`ip -br link | grep nebula`) and whether the host firewall already trusts it (`sudo nft list ruleset | grep -i nebula`, or `iptables -S`).

  > Result:
  > - Port 8100 is free. Ports in use nearby: 127.0.0.1:8000 (Solidtime), 0.0.0.0:8080, 127.0.0.1:8081, 8123.
  > - The tun device is `nebula.mesh`.
  > - The host firewall does not trust it: `trustedInterfaces = [ "lo" ]`, and 8100 is not in the global `allowedTCPPorts`.
  > - `networking.firewall.interfaces."nebula.mesh".allowedTCPPorts = [ 8100 ]` is therefore needed and sufficient (D2).

## 3. AWS setup (manual, by the user)

- [x] 3.1 Confirm who owns AWS account `980921758733` and whether storing technative-casper's backups (TechNative client code) there is allowed. Record the decision here. If it is not allowed, skip task 7.1 and raise a follow-up change.

  > Decision (2026-11-24, user): the account is the user's personal account, not TechNative's. Storing all client code from technative-casper there is allowed, so task 7.1 goes ahead.
- [x] 3.2 Choose the bucket name and region. Create the bucket with:
  - Block Public Access and default SSE-S3
  - versioning
  - lifecycle rules: expire noncurrent versions after 30 days, remove expired delete markers, abort incomplete multipart uploads after 7 days

  Verify with `aws s3api get-public-access-block`, `get-bucket-versioning` and `get-bucket-lifecycle-configuration`.

  > Result: bucket `restic-backup-kaito` in `eu-central-1`. All 4 Block Public Access settings are on, and default encryption is SSE-S3 (AES256, bucket key). Versioning is `Enabled` and lifecycle rule `restic` is present (2026-11-24).
- [x] 3.3 Create the IAM group `restic-clients` with the `${aws:username}` policy from design D8. Create the users `personal-casper`, `gaming-casper`, `technative-casper` and `sakura` under path `/restic/`, add them to the group and create their access keys. Verify with `aws iam get-group --group-name restic-clients`.

  > Result: created by the user. The backup keys cannot call IAM, so this was verified from the keys themselves instead of `get-group`. `sts get-caller-identity` returns `user/restic/<host>` for all 4 keys. Each key can list its own prefix and is denied on `kaito/`, which shows the group policy applies to every user.
- [ ] 3.4 Give the existing user `kaito-backup` the inline policy from design D8 (List/Get/Put/Delete/AbortMultipartUpload on the whole bucket, no `DeleteObjectVersion`) and remove any broader policy it has. Verify with `aws iam list-attached-user-policies` and `list-user-policies`.

  > Open (2026-11-24): `kaito-backup` can still **hard-delete a specific object version** and read the bucket's versioning and lifecycle configuration. The D8 policy grants neither, so a broader policy is still attached to the user, its group or the bucket.
- [x] 3.5 Verify isolation with one client key:
  - put and get under its own prefix succeed
  - listing or reading another host's prefix is denied
  - deleting a non-lock object under its own prefix is denied
  - deleting under `<host>/locks/` succeeds

  > Result (personal-casper key, test objects removed afterwards): own put/get/list succeed and the put returns a version id. Listing the bucket root, listing or writing `sakura/`, and reading `kaito/` are all denied. Deleting own `isolation-test` is denied, while put and delete under own `locks/` succeed. `head-bucket` returns 403 as expected with the prefix condition. restic treats AccessDenied on its bucket check as "exists", which the first `init` in task 6.5 will confirm.

## 4. Secrets

- [x] 4.1 Identify the host keys of personal-casper and gaming-casper with `ssh-keyscan -t ed25519 10.123.0.52` and `10.123.0.51`, matching them against `system1..system8`. In `secrets/secrets.nix`, rename them and `system7` (technative-casper) to their host names, keeping them in `systems`. Verify that `nix eval --json --file secrets/secrets.nix` gives the same recipients before and after (diff empty).

  > Result: only technative-casper (.53) answered the keyscan, and it matches `system7`. Hosts .51, .52 and .54 were offline, so the other two keys were matched against `~/.ssh/known_hosts` instead:
  > - `system2` = gaming-casper (192.168.2.91, `gaming-casper.mesh`)
  > - `system6` = personal-casper (`personal-casper.local`, `.mesh`)
  > - `system8` = neko (not renamed, outside this change's scope)
  > - `system1`, `system3`, `system4` and `system5` match nothing
  >
  > The three keys were renamed. The recipient diff before and after is empty (61 entries).
- [x] 4.2 Add the `restic-*` entries from the table in design D9 to `secrets/secrets.nix`. Verify the recipient lists with `nix eval --json --file secrets/secrets.nix`.

  > Result: 11 entries added (61 → 72). Client passwords have 3 recipients (user1, host, kaito), `restic-kaito-password`, the env files and `restic-htpasswd` have 2. No existing entry changed.
- [x] 4.3 Generate one bcrypt htpasswd line per client with `nix shell nixpkgs#apacheHttpd -c htpasswd -nB <host>`, then run `agenix -e restic-htpasswd.age`. Verify that `agenix -d restic-htpasswd.age | cut -d: -f1` lists the 4 client hosts.

  > Result: generated non-interactively. Each REST password is `openssl rand -hex 32`, written to `RESTIC_REST_USERNAME`/`RESTIC_REST_PASSWORD` in `restic-<host>-env.age`, and hashed with `htpasswd -niB -C 10`. Nothing was printed. `restic-htpasswd.age` lists personal-casper, gaming-casper, technative-casper and sakura, and `htpasswd -vi` confirms each env password matches its hash.
- [x] 4.4 Create the 5 repository passwords (`restic-<host>-password.age` for the 4 clients and kaito) with `agenix -e`, using strong random values such as `openssl rand -base64 48`. Verify that each one decrypts with `agenix -d`.

  > Result: all 5 created by piping `openssl rand -base64 48` into `agenix -e`. Each decrypts to 64 characters.
- [x] 4.5 Create the 4 client environment secrets (`RESTIC_REST_USERNAME`, `RESTIC_REST_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), and `restic-kaito-env.age` (AWS key of `kaito-backup` only). Verify the variable names with `agenix -d <file> | cut -d= -f1`. Never paste keys into chat or commit plaintext.

  > Result: each of the 4 client env files has exactly the 4 variables, and `restic-kaito-env.age` has only the 2 AWS variables. Each AWS key resolves via `sts get-caller-identity` to its own IAM user. `/tmp/kaito-backup` has been removed.
- [ ] 4.6 Make an offline copy (paper or USB) of the 5 repository passwords. Confirm that the `user1` private key has an offline copy too. Verify by reading the copy back on another device.
- [x] 4.7 `git add` every new `.age` file. Verify that `git status` shows them staged.

  > Result: all 11 `secrets/restic-*.age` files are staged (`A`), including the env files re-encrypted after the AWS keys were added. Nothing is committed.

## 5. Registry and repository server

- [x] 5.1 Create `modules/services/backup/restic.nix`, a flake-parts module like `nebula.nix`. It defines `options.casper.backup` with:
  - `server` (host, address, port 8100, dataDir `/srv/restic`)
  - `s3.{bucket,region}` without defaults, set here to the values from task 3.2
  - `retention.{kaito,s3}` with the spec defaults
  - the `clients` submodule with `extraExcludes` and `extraIncludes`

  `git add` the file. Verify that `nix flake check` passes.
  Result (2026-11-24): done; bucket `restic-backup-kaito` / `eu-central-1` set in the module. Also adds internal read-only `casper.backup.repository.{rest,s3}` URL helpers and exports `flake.backup`. Flake check: only the pre-existing neko/server-casper nextcloud failure.
- [x] 5.2 Create `modules/services/backup/restic-server.nix`, which exports `backup-restic-server` (design D2 and D7). It contains:
  - `services.restic.server` with `listenAddress = "8100"`, `dataDir = "/srv/restic"`, `appendOnly`, `privateRepos` and `htpasswd-file`
  - a tmpfiles rule for `/srv/restic`
  - the firewall opening on the Nebula interface only
  - age secrets owned by `restic` for htpasswd, the prune key and the client passwords
  - `maint-local-<host>` and `maint-s3-<host>` jobs for every registered client, plus `maint-s3-kaito` when `config.services.restic.backups ? state-s3`

  Confirm that 25.11 accepts `paths = [ ]`. If not, use the oneshot fallback from D7. Verify that `nix flake check` passes.
  Result (2026-11-24): done. `paths = [ ]` works in 26.05 (backup step skipped, only unlock/forget/check), so no oneshot fallback. Deviation: `maint-s3-kaito` lives in `restic-kaito-state.nix`, because testing `backups ? state-s3` inside the same option recurses; it exists exactly when `state-s3` exists. Maintenance and client jobs pass `--retry-lock` so a weekly prune and an hourly backup wait for each other instead of failing.
- [x] 5.3 Import `backup-restic-server` on kaito and build its toplevel. Verify with `nix eval` that:
  - 8100 is not in `networking.firewall.allowedTCPPorts`
  - 8100 is in `networking.firewall.interfaces."<tun>".allowedTCPPorts`
  - `services.restic.server.dataDir` is `/srv/restic`
  Result (2026-11-24): kaito toplevel builds. 8100 not in global `allowedTCPPorts`; `interfaces."nebula.mesh".allowedTCPPorts = [ 8100 ]`; dataDir `/srv/restic`; 10 restic jobs (4 maint-local, 5 maint-s3, state-s3); all restic secrets owned by `restic`.
- [ ] 5.4 Deploy kaito and test by hand:
  - from a mesh host, `curl -s -o /dev/null -w '%{http_code}' http://kaito.mesh:8100/` returns 401
  - with host X's credentials, `http://kaito.mesh:8100/<other-host>/config` is refused
  - from the LAN and through the public endpoint, port 8100 does not connect

## 6. Home backup module and first client: personal-casper (non-critical)

- [x] 6.1 Create `modules/services/backup/restic-home.nix`, which exports `backup-restic-home` (design D4 and D5). It contains:
  - the exclude ladder as a Nix list, rendered to `/etc/restic/home-excludes`
  - the jobs `home-kaito` and `home-s3`, with the AC power condition, idle priority, persistent timers and `inhibitsSleep` if available
  - the registry assertion
  - the per-host age secrets

  `git add` the file. Verify that `nix flake check` passes.
  Result (2026-11-24): done; exclude file has 87 lines. technative-casper: repos `rest:http://kaito.mesh:8100/technative-casper/` and `s3:s3.eu-central-1.amazonaws.com/restic-backup-kaito/technative-casper`, `ConditionACPower`, Nice 19, IO idle, `inhibitsSleep`, timers hourly/10m and daily/1h. technative-casper toplevel builds.
- [x] 6.2 Verify the unregistered-host scenario. Evaluating `nixosConfigurations.neko.extendModules { modules = [ self.modules.nixos.backup-restic-home ]; }` must fail with the assertion message that names the missing registration.
  Result (2026-11-24): tested on kaito (not a client) instead of neko, because neko does not evaluate (pre-existing insecure nextcloud-32.0.15). The toplevel throws "backup-restic-home is imported on kaito, but the host is not registered: add `casper.backup.clients.kaito = { };` next to its Nebula node."
- [x] 6.3 Add `casper.backup.clients.personal-casper = { };` next to its Nebula node and import `backup-restic-home`. Verify that `nix build .#nixosConfigurations.personal-casper.config.system.build.toplevel` succeeds.
  Result (2026-11-24): registered and imported; personal-casper toplevel builds. gaming-casper, technative-casper and sakura are registered and import the module too (7.x keeps their runtime steps).
- [ ] 6.4 Run the dry-run audit on personal-casper with the commands in design D4. Verify the spec scenarios in the `-vv` output:
  - included: Documents, `.ssh`, `.gnupg`, `git/**/.git`, Firefox `places.sqlite`
  - excluded: Downloads, `.cache`, `.claude`, `.local/share/opencode`, `node_modules`, `git/**/target`, Firefox `storage/`, `.config/clipse`, `.config/*/Cache`

  Add registry `extraExcludes` where needed. Record the total size and check that it fits in kaito's free space.
- [ ] 6.5 Rebuild and deploy kaito to get the personal-casper maintenance jobs and password secret, then deploy personal-casper. Run `systemctl start restic-backups-home-kaito restic-backups-home-s3`. Verify that `sudo restic-home-kaito snapshots` and `sudo restic-home-s3 snapshots` each show a snapshot with host `personal-casper`, tag `home` and path `/home`.
- [ ] 6.6 Verify that deletion is impossible. `sudo restic-home-kaito forget <id>` and `sudo restic-home-s3 forget <id>` must both be refused, and the snapshot must still be listed.
- [ ] 6.7 Verify independence. Stop Nebula on personal-casper and start both jobs: `home-kaito` fails and `home-s3` succeeds. Start Nebula again.
- [ ] 6.8 Restore drill. Restore `/home/casper/Documents` from both destinations into `/tmp/restore-*` with `restic-home-kaito restore latest --include … --target …` and the S3 equivalent. Verify with `diff -r` against the live directory.
- [ ] 6.9 Manual hardware test on the laptop:
  - suspend it through a scheduled run, then resume it on AC: the missed run starts (`journalctl -u restic-backups-home-s3`)
  - on battery, `systemctl start` reports the unmet `ConditionACPower`
  - during a run, `systemd-inhibit --list` shows the sleep inhibitor, if enabled
- [ ] 6.10 On kaito, run `systemctl start restic-backups-maint-local-personal-casper restic-backups-maint-s3-personal-casper`. Verify that both units succeed, the newest snapshot remains and the local check reports the data subset it read.

## 7. Remaining clients

- [ ] 7.1 technative-casper, only if task 3.1 approved it. Register the host, import the feature and build. Run the dry-run audit (about 30G expected, `/home/lucak` covered). Rebuild kaito and deploy both. Trigger both jobs. Verify the snapshots on both destinations and restore one file from each.
  Progress (2026-11-24): AWS account approved (3.1). Registered, imported, toplevel builds. Dry-run audit of `/home/casper` (as casper, `/home/lucak` unreadable but 4K): 28.6 GiB scanned, 26.3 GiB new, 16.9 GiB stored after compression; included Documents, .ssh, .gnupg, git/**/.git, places.sqlite, .config/Signal, .local/share/keyrings; zero matches for Downloads, .cache, .claude, .local/share/opencode, node_modules, git/**/target, firefox storage, .config/clipse, .config/*/Cache. Deploy, trigger and restore still open.
- [ ] 7.2 gaming-casper. Register the host, import the feature and build. Run the dry-run audit and add `extraExcludes` for games or other bulky data it finds. Rebuild kaito and deploy both. Trigger both jobs. Verify the snapshots on both destinations and restore one file from each.
- [ ] 7.3 sakura. Tell antonia first that her home will be backed up. Register the host, import the feature and build. Run the dry-run audit. Rebuild kaito and deploy both. Trigger both jobs. Verify the snapshots, and that `restic-home-s3 ls latest /home/antonia` lists her files.
- [ ] 7.4 After all clients are done, record `df -h /` and `sudo du -sh /srv/restic/*` on kaito. Verify that at least 20% of the filesystem stays free.

## 8. kaito state backup

- [ ] 8.1 Create `modules/services/backup/restic-kaito-state.nix`, which exports `backup-restic-kaito-state` (design D10). It contains:
  - `services.postgresqlBackup` (`backupAll`, `/var/backup/postgresql`, zstd, its own timer disabled)
  - `services.vaultwarden.backupDir`
  - the conditional Solidtime `pg_dump`
  - a prepare script with `set -euo pipefail`
  - the excludes, the Docker volume ladder and the excludes from the task 2.1 audit
  - the `state-s3` job, daily at 03:30 and persistent
  - the age secrets `restic-kaito-password` and `restic-kaito-env`

  `git add` the file. Import it on kaito. Verify that the kaito toplevel builds.
  Progress (2026-11-24): module written and imported on kaito; kaito toplevel builds. Open: add the excludes from the task 2.1 `/var/lib` audit (waiting for the `du` output).
- [x] 8.2 Verify the conditional dumps. `backupPrepareCommand` must contain the Solidtime dump for the normal kaito config. It must not contain it when evaluated through `extendModules` with `virtualisation.oci-containers.containers = lib.mkForce { }`.
  Result (2026-11-24): normal kaito config contains the Solidtime `pg_dump`; with `oci-containers.containers = lib.mkForce { }` the prepare script only starts postgresqlBackup and backup-vaultwarden.
- [ ] 8.3 Deploy kaito and run `systemctl start restic-backups-state-s3`. Verify with `restic-state-s3 ls latest` that:
  - these are present: `/var/lib/nixos`, `/var/lib/hass/.storage`, Zigbee2MQTT, `/var/lib/private/matter-server`, `/var/lib/thread`, the PostgreSQL, Vaultwarden and Solidtime dumps in `/var/backup`, and the `solidtime-storage` volume
  - these are absent: `/var/lib/docker/overlay2`, `/var/lib/postgresql`, `/var/lib/vaultwarden/db.sqlite3` and anything from `/srv/restic`
- [ ] 8.4 Verify the failure path. Stop `docker-solidtime-db.service` and start the state job: the unit must fail. Start the container again, rerun the job and verify that it succeeds.
- [ ] 8.5 Restore drill:
  - Vaultwarden: in the restored `db.sqlite3`, `PRAGMA integrity_check` returns `ok` and the cipher count matches the live database
  - Atuin: the restored pg_dumpall file loads with `psql -f` into a throwaway PostgreSQL, and the history row count matches
  - Solidtime: `pg_restore --list` succeeds on the restored dump
- [ ] 8.6 Run `systemctl start restic-backups-maint-s3-kaito`. Verify that it succeeds.

## 9. Runbook, final checks and follow-through

- [ ] 9.1 Write `docs/backup-restore.md`. It covers:
  - the architecture and the wrapper commands
  - restoring files or a whole home
  - a fresh-machine restore without agenix (environment variables plus the offline secrets)
  - kaito disaster recovery (dumps, Vaultwarden, HA, Zigbee, Matter, Thread)
  - the AWS setup, including the policy JSON
  - adding a new client host (registry, IAM user, htpasswd line, secrets, kaito rebuild)
  - the recovery circle and where the offline copies are kept

  Verify that every command in it was used in sections 6–8.
- [ ] 9.2 Full-disaster drill. On a machine without agenix, using only the offline password and an IAM key, run `restic -r s3:… snapshots` and restore one file. Verify that it works.
- [ ] 9.3 Run `nix flake check` and build the toplevels of kaito, personal-casper, gaming-casper, technative-casper and sakura. Verify that the unaffected hosts still evaluate: neko, plus server-casper (aarch64) with `nix eval .#nixosConfigurations.server-casper.config.system.build.toplevel.drvPath`.
- [ ] 9.4 One week after the last deployment, check `systemctl list-timers 'restic-backups-*'` and the journals of the `maint-*` units on kaito. Verify that they succeeded, that the snapshots were thinned according to retention, and that `systemctl --failed` is empty on every host involved.
- [ ] 9.5 Run `openspec validate add-restic-backups --strict` and verify that it passes.
