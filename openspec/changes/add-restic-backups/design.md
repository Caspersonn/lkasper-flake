# Design

## Context

See `proposal.md` (Why) for motivation and the specs for the requirements. The current state that shapes this design:

- **No backup tooling exists in `modules/`.** borgbackup is only a CLI package. An earlier kaito restic media backup was removed in commit 7401466. `secrets/media-backup-password.age` is a leftover that no module uses.
- **kaito** (x86_64) has a single 500G NVMe with one 440G ext4 root filesystem: 82% used, 80G free. It holds 130 system generations because GC never ran. It is the Nebula lighthouse (`10.123.0.1`, reachable as `kaito.mesh` through `networking.extraHosts`, which `modules/services/networking/nebula.nix` sets). Port 8000 is taken by Solidtime (staged change). Solidtime's PostgreSQL runs in Docker (`solidtime-db`, volume `solidtime-database`). The `solidtime-net` network is created by a oneshot unit. Atuin uses the NixOS PostgreSQL. Vaultwarden uses SQLite in `/var/lib/vaultwarden`.
- **Nebula** has a fully open internal firewall (`port = "any"` between all nodes, including the phone). The flake-level `casper.nebula` option set in `nebula.nix` is the existing precedent for flake-wide registries that NixOS modules read through closure.
- **Secrets:** almost every secret uses `users ++ systems`. The host keys `system1..system8` are anonymous. technative-casper is `system7`. kaito and sakura are named. All four client hosts import the `age` module.
- **Measured home size:** technative-casper is ~30G under the selection policy (visible 2.8G, `~/git` without build junk 26G, hidden allowlist ~1G). The other hosts are unmeasured.
- **Versions:** nixpkgs ships restic 0.18.1, which supports `RESTIC_REST_USERNAME/PASSWORD` and `--insecure-no-password`, and restic-rest-server 0.14.0.
- **Architecture:** all affected hosts are x86_64. Nothing in the modules is architecture-specific, and restic and rest-server build on aarch64 too, so server-casper (aarch64) could import them later unchanged.

## Goals / Non-Goals

**Goals:**
- One reusable, import-only module per role (client, server, kaito state, cleanup). The modules get their shared settings from one flake-level registry.
- Snapshot identity is deterministic (`paths = [ "/home" ]`, fixed tag), so changing the policy never breaks parent detection or retention grouping.
- No credential on a client host can delete history.
- The selection policy can be checked before any job runs.

**Non-Goals:**
- S3 Object Lock / compliance mode. It conflicts with `restic prune` and adds retention cost. Versioning plus a 30-day noncurrent expiry gives enough protection against deletion.
- Glacier / Infrequent Access storage classes. restic reads metadata often and the data volume is small.
- A web UI (Backrest, as in mipnix), `restic copy` between the destinations, and automatic htpasswd/IAM provisioning.
- Tightening the Nebula firewall to groups. This is a separate change. The REST server needs credentials anyway.
- Failure alerting (follow-up: `OnFailure=` notification).

## Decisions

### D1 — Each client writes directly to both destinations (topology A)
Each client runs two independent jobs: `home-kaito` (hourly) and `home-s3` (daily).
- **Alternative (B):** clients only back up to kaito, and kaito `restic copy`s to S3. Rejected. The offsite copy would depend on kaito's single disk and uptime, kaito would need every host's S3 write path, and a corrupted kaito repository would propagate to S3.
- **Cost of A:** each client uploads twice. Incremental runs are small, so this is acceptable.

### D2 — rest-server on kaito, mesh-only, plain HTTP on port 8100
`services.restic.server` runs with `appendOnly = true`, `privateRepos = true` and `htpasswd-file` from agenix (`restic-htpasswd.age`, owner `restic`, bcrypt entries). `listenAddress = "8100"` uses the module's socket activation. The data directory is **`/srv/restic`**, not the default `/var/lib/restic`, so the kaito state backup of `/var/lib` cannot pick up client repositories. A tmpfiles rule creates the directory with mode 0700 owned by `restic:restic`.

The port is opened only with `networking.firewall.interfaces."nebula.mesh".allowedTCPPorts` and is never added to the global `allowedTCPPorts`. Nebula already encrypts and authenticates nodes, so TLS (nginx + ACME) would only add moving parts. Before choosing 8100, implementation verifies that nothing listens on it (`ss -ltnp`) and checks the real tun device name (`ip link`). It also checks whether the nebula NixOS module already marks the tun device as trusted. That does not change the outcome, because the port must still be closed on LAN and public interfaces.

- **Alternative:** SFTP to a dedicated user, as in mipnix. Rejected: append-only cannot be enforced server-side, and it needs shell accounts and known-hosts pinning.
- **Alternative:** NFS/SMB mount. Rejected: there is no per-host isolation and no append-only.

Clients use the repository `rest:http://kaito.mesh:8100/<hostname>/`, with `RESTIC_REST_USERNAME/PASSWORD` in their environment file. The credentials are not part of the URL, which is visible in unit files and the Nix store.

### D3 — One repository per host per destination
Deduplication happens within a host, which covers most of the benefit. `privateRepos` and per-host IAM prefixes isolate hosts from each other.
- **Alternative:** one shared repository. Rejected: it needs one shared password and gives no isolation.
- **Alternative:** one repository per dataset, as in mipnix. Rejected: it adds more repositories and passwords for no gain, because only `/home` is backed up.

### D4 — Selection by a generated, ordered exclude file (the "ladder")
`paths` is always `[ "/home" ]`. The job adds `--exclude-caches`, `--one-file-system` and `--tag home`.

restic exclude semantics that the ladder relies on:
- an absolute pattern also matches everything below the matched path
- `!` re-includes a path
- the last matching pattern wins

The ladder never re-includes a path whose ancestor stays excluded. Each ancestor is itself re-included, then its children are excluded again, then specific children are re-included:

```
/home/*/.*                       # all hidden entries out ...
!/home/*/.ssh                    # ... allowlisted ones back in
!/home/*/.gnupg
!/home/*/.docker
!/home/*/.aws
/home/*/.aws/sso/cache
/home/*/.aws/cli/cache
!/home/*/.mozilla                # profiles minus storage/cache2/startupCache/crashes/minidumps/
/home/*/.mozilla/firefox/*/storage   #   datareporting/saved-telemetry-pings, "Crash Reports"
...                              # same set for .thunderbird
!/home/*/.config
/home/*/.config/open-webui-desktop   # denylist (see spec)
...
!/home/*/.local
/home/*/.local/*
!/home/*/.local/share
/home/*/.local/share/*
!/home/*/.local/share/keyrings   # + fish, FreeCAD, bambu-studio, orca-slicer
!/home/*/.*rc
!/home/*/.*_history
!/home/*/.gitconfig              # + .git-credentials, .netrc, .profile
<registry extraIncludes, as ! patterns>
/home/*/Downloads
/home/*/go/pkg
/home/*/.config/**/Cache         # Electron/Chromium cache dirs: Code Cache, GPUCache, Dawn*Cache,
...                              #   GrShaderCache, ShaderCache, Service Worker, Crashpad, CachedData, blob_storage
node_modules                     # build junk at any depth (relative patterns)
...
/home/*/git/**/target            # ambiguous names only below ~/git
...
<registry extraExcludes>
```

Build junk and cache excludes come **last**, so no allowlist entry can re-include them, for example `~/.config/opencode/node_modules`.

The policy lives in `restic-home.nix` as a Nix list. It is rendered to `/etc/restic/home-excludes` through `environment.etc` and passed as `--exclude-file`. The `exclude` option is not used, because a stable, well-known path lets you audit the policy:

```
nix build .#nixosConfigurations.<host>.config.environment.etc."restic/home-excludes".source
sudo restic -r /tmp/restic-audit init --insecure-no-password
sudo restic -r /tmp/restic-audit --insecure-no-password backup --dry-run -vv \
  --exclude-file=./result --exclude-caches --one-file-system /home
```

This works before the host imports the feature and needs no repository or secrets.

- **Alternative:** `dynamicFilesFrom` / `--files-from`. Rejected: the snapshot paths would change whenever the file list changes, which breaks parent detection and `forget` grouping by `host,paths`, and every run would walk the tree twice.
- **Alternative:** per-user include lists. Rejected: they miss new visible directories and need antonia and lucak spelled out.

### D5 — Client job shape
Both jobs share the following settings:
- `initialize = true`, with no `pruneOpts` and no checks on clients
- `passwordFile` from `restic-<host>-password.age` and `environmentFile` from `restic-<host>-env.age`
- `timerConfig` with `Persistent = true`; `RandomizedDelaySec` is 10 min for kaito and 1 h for S3
- `serviceConfig.Nice = 19` and `IOSchedulingClass = "idle"`
- `unitConfig.ConditionACPower = true`. The condition holds on desktops, which have no battery.
- `inhibitsSleep = true`, if the option exists in 25.11, so a laptop does not suspend in the middle of an upload

restic exit code 3 (snapshot created, some files unreadable) remains a unit failure, as the spec requires. The module's `createWrapper` provides `restic-home-kaito` and `restic-home-s3` commands for manual `snapshots`, `ls`, `restore` and `mount`.

Hosts register with `casper.backup.clients.<host> = { };` next to `casper.nebula.nodes.<host>` in their `configuration.nix`. The NixOS module asserts that the registry contains `config.networking.hostName`. It reads the registry entry with `or { … }`, so the assertion message is shown instead of an attribute error.

### D6 — Flake-level registry `casper.backup`
`modules/services/backup/restic.nix` is a flake-parts module with the `{ config, lib, ... }:` form, like `nebula.nix`. It defines:
- `server.{host = "kaito"; address = "kaito.mesh"; port = 8100; dataDir = "/srv/restic"}`
- `s3.{bucket, region}`, which have **no defaults**, so evaluation fails until the user fills them in
- `retention.{kaito, s3}` as lists of `--keep-*` flags. The spec defaults are kaito: hourly 24 / daily 7 / weekly 4, and S3: daily 7 / weekly 4 / monthly 12.
- `clients` as `attrsOf (submodule { extraExcludes; extraIncludes; })`

kaito must know every client to generate its maintenance jobs, so the registry has to be flake-wide and cannot be a per-host NixOS option.

- **Alternative:** hard-code the host list in the server module. Rejected: adding a host would then mean editing two places.

### D7 — Retention and checks only on kaito, as prune-only restic jobs
For each registered client, and for `kaito` itself on S3 only, the server module generates `services.restic.backups` entries with `paths = [ ]`. The NixOS module then skips the backup step and runs only `forget --prune` and `check`. These entries are:
- `maint-local-<host>`, run as `user = "restic"` against the repository directory `/srv/restic/<host>`. It goes straight to the filesystem, so append-only does not block pruning. It uses `pruneOpts = retention.kaito` and `checkOpts = [ "--read-data-subset=10%" ]`.
- `maint-s3-<host>`, also run as `restic`. It uses `environmentFile` from `restic-kaito-env.age` (the key of IAM user `kaito-backup`, the only delete-capable key), `pruneOpts = retention.s3` and a plain structural `check`, which avoids egress for pack reads. On kaito this secret is therefore readable by `restic` (owner `restic`, mode 0400); the root-run `state-s3` job reads it as well.

All entries use `initialize = false`, and they run weekly on Sunday from 04:00 with `RandomizedDelaySec = 3h`, so they spread out. Their password files are the clients' `restic-<host>-password.age`, decrypted on kaito with owner `restic`. Implementation verifies that 25.11 accepts an empty `paths` without `dynamicFilesFrom`. If it does not, the fallback is a small custom oneshot unit with the same commands.

- **Alternative:** clients prune their own repositories. Rejected: the client would need delete rights, which defeats D2 and the IAM design.
- **Alternative:** prune from the admin workstation. Rejected: it is not always on.

### D8 — S3 layout and IAM (created manually, documented in the runbook)
The flake does not manage AWS resources. The user creates them in account `980921758733`:
- **Bucket:**
  - Block Public Access on, default SSE-S3, versioning on
  - lifecycle rules: expire noncurrent versions after 30 days, delete expired delete markers, abort incomplete multipart uploads after 7 days
- **Bucket name and region:** `restic-backup-kaito` in `eu-central-1` (created by the user before apply).
- **Clients:**
  - one IAM user per workstation, named exactly after the host, under path `/restic/`
  - all of them are in the group `restic-clients`, which has a single policy built on `${aws:username}`:
    - `s3:ListBucket` on the bucket, with the condition `s3:prefix` like `${aws:username}` or `${aws:username}/*`
    - `s3:GetBucketLocation`
    - `s3:GetObject`, `s3:PutObject` and `s3:AbortMultipartUpload` on `bucket/${aws:username}/*`
    - `s3:DeleteObject` only on `bucket/${aws:username}/locks/*`
- **kaito (state + prune):** the pre-existing IAM user `kaito-backup` is kaito's only key. Its inline policy grants `s3:ListBucket` and `s3:GetBucketLocation` on the bucket and `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` and `s3:AbortMultipartUpload` on `bucket/*`. It is used both for kaito's own `kaito/` state repository and for pruning every prefix. It deliberately has **no** `s3:DeleteObjectVersion`, `s3:PutBucketVersioning` or `s3:PutLifecycleConfiguration`, so even this key can only soft-delete: versioning keeps every pruned object for 30 days.
  - Rationale: the design already placed the delete-capable prune key only on kaito, so merging it with kaito's state key loses no isolation and saves one IAM user and one secret.
  - **Alternative:** a separate `restic-prune` user next to a scoped `kaito` user. Rejected: both keys would live on the same host with the same recipients.

Repository URL: `s3:s3.eu-central-1.amazonaws.com/restic-backup-kaito/<hostname>`. The environment files contain `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

- **Alternative:** reuse the existing `aws_credentials.age`. Rejected: every host can decrypt it, and it is not scoped.
- **Alternative:** the TechNative MFA/Bitwarden flow. Rejected: a systemd timer cannot use MFA.

### D9 — Secrets
In `secrets/secrets.nix`, the involved anonymous keys are renamed: `system7` becomes `technative-casper`, and the keys of personal-casper and gaming-casper are identified with `ssh-keyscan -t ed25519` over the mesh and renamed the same way. They stay in the `systems` list, so existing recipients do not change and no rekey is needed. The new entries are:

| Secret | Recipients | Content |
|---|---|---|
| `restic-<host>-password.age` (4 clients + kaito) | `users ++ [ <host> kaito ]` | repository password, shared by both repos of the host |
| `restic-<host>-env.age` (4 clients) | `users ++ [ <host> ]` | `RESTIC_REST_USERNAME/PASSWORD`, AWS key of IAM user `<host>` |
| `restic-kaito-env.age` | `users ++ [ kaito ]` | AWS key of IAM user `kaito-backup` (state backup and S3 pruning) |
| `restic-htpasswd.age` | `users ++ [ kaito ]` | bcrypt `htpasswd -B` entries, one per client |

`restic-kaito-password.age` belongs to the first row with recipients `users ++ [ kaito ]`.

The modules reference the files as `inputs.self + "/secrets/restic-${hostName}-…age"`, following whatever path convention the existing modules use. On kaito, all `restic-*-password` secrets are owned by `restic` with mode 0400. Root reads them anyway for the state job.

One password per host, instead of one per destination, keeps the offline recovery sheet short. Splitting it would gain nothing: anyone who compromises the host has both passwords anyway.

Secrets are created with `agenix -e`, either interactively by the user or by piping generated values or a local key file into it (agenix uses `cp /dev/stdin` as editor when stdin is not a terminal). Keys are never printed, pasted into the chat or committed in plain text.

### D10 — kaito state backup
The state backup is a `services.restic.backups.state-s3` job that runs as root:
- `paths = [ "/var/lib" "/var/backup" ]`, repository `…/<bucket>/kaito`, `--tag state`, `--exclude-caches`, `--one-file-system`
- daily at 03:30, `Persistent = true`, `RandomizedDelaySec = 15m`

Dumps run in `backupPrepareCommand` with `set -euo pipefail`, so a failing dump fails the job:
- **PostgreSQL:** `services.postgresqlBackup` runs with `backupAll = true` (pg_dumpall, which includes roles), `location = /var/backup/postgresql` and zstd compression. Its own timer is disabled (`startAt = [ ]`, verify), and the prepare step runs `systemctl start postgresqlBackup.service`, which blocks and fails if the dump fails. Added only when `config.services.postgresql.enable` is set.
- **Vaultwarden:** `services.vaultwarden.backupDir = "/var/backup/vaultwarden"`, and the prepare step runs `systemctl start backup-vaultwarden.service`, which uses the upstream SQLite `.backup` script. Added only when `config.services.vaultwarden.enable` is set.
- **Solidtime:** `docker exec solidtime-db pg_dump -U solidtime -Fc solidtime` writes to a temporary file that is then moved to `/var/backup/solidtime/solidtime.dump`. Added only when `config.virtualisation.oci-containers.containers ? solidtime-db`.

Excludes:
- `/var/lib/postgresql`. The pg_dumpall dump covers it.
- `/var/lib/vaultwarden/db.sqlite3*` only. Attachments, RSA keys and the config are still captured live, in case the upstream backup script skips something.
- `/var/lib/hass/home-assistant_v2.db*`, `/var/lib/private/ollama`, `/var/lib/redis-*`, `/var/lib/systemd/coredump`, `/var/lib/containers`, `/var/lib/machines` and `/var/lib/restic` (defensive).
- A Docker ladder that keeps only the application-storage volumes:
  ```
  /var/lib/docker/*
  !/var/lib/docker/volumes
  /var/lib/docker/volumes/*
  !/var/lib/docker/volumes/solidtime-storage
  ```
- Further excludes come from a `sudo du -xsh /var/lib/* /var/lib/private/*` audit, for example Jellyfin metadata or orphaned directories such as `lidarr`, `jackett`, `nextcloud`, `*.legacy` and `zigbee2mqtt.backup.*`. The user decides which orphaned directories to delete.

The state job has no `pruneOpts`. D7 covers its retention.

### D11 — Daily cleanup module (`modules/nix/gc.nix`, `flake.modules.nixos.nix-gc`)
The user asked for a daily `nix-collect-garbage` service. NixOS already provides one:
- `nix.gc = { automatic = true; dates = "daily"; options = "--delete-older-than 7d"; persistent = true; randomizedDelaySec = "45min"; }`
- `nix.optimise = { automatic = true; dates = [ "01:30" ]; }`, scheduled so it does not overlap the 03:30 state backup

Docker pruning is a custom `docker-image-prune` oneshot with a daily persistent timer. It runs `docker image prune --force --filter until=168h`, which removes only dangling images. It is wrapped in `lib.mkIf config.virtualisation.docker.enable`.

- **Alternative:** `virtualisation.docker.autoPrune`. Rejected: it runs `docker system prune`, which also removes unused networks such as `solidtime-net`, created once by a oneshot unit. `--all` would also drop the images of stopped containers. `--volumes` is never used.
- **Alternative:** `nix-collect-garbage -d`. Rejected: it removes every rollback.

kaito is the only host that imports the module in this change. gaming-casper acts as a remote builder and binary cache, so its retention needs separate thought.

### Module and file layout

| File | Kind | Export | Imported by |
|---|---|---|---|
| `modules/services/backup/restic.nix` | flake-parts options | `casper.backup` registry (+ shared helpers) | auto (import-tree) |
| `modules/services/backup/restic-home.nix` | NixOS module | `flake.modules.nixos.backup-restic-home` | personal-casper, gaming-casper, technative-casper, sakura |
| `modules/services/backup/restic-server.nix` | NixOS module | `flake.modules.nixos.backup-restic-server` (server + D7 maintenance) | kaito |
| `modules/services/backup/restic-kaito-state.nix` | NixOS module | `flake.modules.nixos.backup-restic-kaito-state` | kaito |
| `modules/nix/gc.nix` | NixOS module | `flake.modules.nixos.nix-gc` | kaito |
| `docs/backup-restore.md` | runbook | — | not imported (import-tree only loads `.nix` under `modules/`) |

Hosts keep using `makeNixos`. Each one only adds imports and a `casper.backup.clients.<host>` entry. Home Manager is not touched.

## Risks / Trade-offs

- **kaito disk runs full** (80G free, ~30G per host on the first snapshot) → GC ships first and free space is measured. Every host gets a dry-run audit before it is enabled, and hosts are added one at a time. Retention lives in the registry. A USB SSD for `/srv/restic` is the escape hatch.
- **kaito's repository shares its disk with the OS** → it exists for fast restores only. S3 is the copy that has to survive, and kaito's own state goes only to S3.
- **kaito holds every repository password and the S3 prune key**, so a compromised kaito can read all backups and delete S3 snapshots → noncurrent versions stay for 30 days, which gives time to notice. This is accepted in exchange for an always-on prune host.
- **The Nebula mesh is fully open, phone included** → the REST port needs bcrypt credentials, and each host is limited to its own repository. Tightening the mesh firewall is left as a follow-up.
- **The `s3:prefix` condition on ListBucket may break restic's bucket-existence check** (HeadBucket has no prefix) → if `init` fails, ListBucket is allowed without the condition. That exposes only the names of other hosts' objects, whose content is encrypted.
- **Mistakes in the exclude ladder silently drop data** → before enabling a host, a dry-run audit checks the spec scenarios. After the first snapshot, `restic ls latest` spot-checks key paths and a restore drill runs per destination.
- **Hourly kaito backups on mobile connections** → incremental runs are small, the jobs require AC power and run at idle I/O priority, and the first full upload to S3 resumes from the already uploaded packs after an interruption.
- **Lock contention between the weekly prune and hourly client backups** → restic locking prevents corruption. A prune that fails is retried the next week, and the jobs run at night.
- **S3 costs**: versioning keeps pruned data for 30 days, and prune repacking downloads some packs → at ~100–150G in S3 Standard this stays in the low single-digit dollars per month.
- **Ownership of account 980921758733 is unverified**, and the work laptop contains TechNative client code → a task requires confirmation before technative-casper's S3 job is deployed.
- **The GC deletes rollbacks older than 7 days**, and stale boot menu entries remain until the next rebuild → choose recent entries when booting. The first manual GC run on kaito happens under supervision.
- **antonia's home on sakura is backed up**, and the admin can read it → tell her before enabling sakura.
- **Recovery circle**: agenix secrets are encrypted to `user1`, whose private key is inside the backups, and the restic passwords are also in Vaultwarden, which runs on kaito → the runbook requires an offline copy (paper/USB) of every restic password and of the `user1` key. A restore drill must work without agenix.

## Migration Plan

1. **Cleanup first, as its own deployment.** Import `nix-gc` on kaito and deploy. Run the GC once by hand, then record `df -h /`, `docker system df` and `sudo du -xsh /var/lib/* /var/lib/private/*`.
2. **AWS (manual).** Create the bucket, versioning, lifecycle rules, the `restic-clients` group and policy, the IAM users per workstation and their access keys, and the inline policy of the existing `kaito-backup` user. Fill in `casper.backup.s3.{bucket,region}`.
3. **Secrets.** Rename the system keys, add the `secrets.nix` entries, and run `agenix -e` for each file.
4. **Server.** Import `backup-restic-server` on kaito. Verify the port, the tun device name and the firewall from both the mesh and the LAN.
5. **personal-casper first.** It is the least critical machine and holds no client data. Run the dry-run audit, register the host, import the feature, and deploy kaito (to generate its maintenance jobs) and then the host. Verify both destinations, deletion denial and independence, and run a restore drill plus the suspend/AC hardware test.
6. **technative-casper** (only after the AWS account is confirmed), **gaming-casper** and **sakura**, one at a time with the same steps, adding registry `extraExcludes` where the audit calls for them.
7. **kaito state backup** after the `/var/lib` audit. Do a restore drill of the Vaultwarden and PostgreSQL dumps.
8. **Runbook and offline recovery copy.**

**Rollback:** removing an import removes its timers and units. The repositories and S3 data stay, and you can still restore from them with plain restic and the offline secrets. Removing `nix-gc` stops future collection, but generations that were already collected cannot be restored.

## Open Questions

- Bucket name and region (for example `eu-central-1`). These are registry values, set during step 2.
- Per-host `extraExcludes` and `extraIncludes`, such as `~/Games` on gaming-casper, or `.librewolf` and `.zen` if wanted. These follow from the dry-run audits.
- Extra `/var/lib` excludes and which orphaned directories to delete. These follow from the audit in step 1.
- Follow-up changes:
  - failure alerting
  - `/srv` (Minecraft) and `/mnt/audio`
  - server-casper and neko
  - `nix-gc` on other hosts
  - an external disk for kaito's repository
  - group-based Nebula firewall rules
