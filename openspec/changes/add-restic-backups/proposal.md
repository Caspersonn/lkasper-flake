# Proposal

## Why

None of the workstations has a backup of personal data today. Home directories and `~/git` (unpushed branches, stashes, uncommitted work) exist only on their own disk. kaito also hosts irreplaceable state (Vaultwarden, Home Assistant/Zigbee/Matter/Thread pairing, Atuin history including the synced AI threads, Solidtime) on a single NVMe that has no copy anywhere. kaito has only 80G free of 440G because Nix garbage collection never runs (130 system generations). That space must be reclaimed before kaito can receive backups.

## What Changes

- Add restic backups of `/home` (including `/home/*/git`) for **personal-casper, gaming-casper, technative-casper and sakura**. Each host sends its backups to two independent destinations:
  - **kaito**: a restic REST server reachable only over the Nebula mesh. It is append-only, each host can reach only its own repository, and it keeps snapshots for a short period so restores are fast.
  - **AWS S3** in account `980921758733`: one bucket, one prefix per host, kept long-term, offsite.
- Select home data with a "personal data yes, caches no" policy:
  - Visible top-level entries are backed up, except `Downloads` and known caches.
  - Hidden entries are backed up only when allowlisted: `.ssh`, `.gnupg`, `.aws`, `.docker`, `.mozilla` (Firefox profiles without caches and site storage), `.config` (minus heavy Electron/app caches), selected `.local/share` entries, and shell/tool dotfiles.
  - Build and dependency directories (`node_modules`, `.venv`, `.terraform`, `target`, ...) are excluded everywhere they occur; `.git` directories are kept.
  - AI conversation history (`.claude`, opencode sessions) is **not** backed up here. It is synced to Atuin on kaito and is covered by kaito's state backup.
- Back up kaito's `/var/lib` (kaito only) to S3. Databases are backed up from consistent dumps (NixOS PostgreSQL, Vaultwarden SQLite, Solidtime's dockerised PostgreSQL), not from live files. The rest-server repository data is excluded so client repositories are not copied twice. kaito has no backup on itself; a copy on the same disk would not survive a disk failure.
- Run retention (`forget --prune`) and integrity checks only on kaito, with a dedicated S3 key that is allowed to delete. Client hosts cannot remove snapshots on either destination.
- Add a daily cleanup on kaito: Nix garbage collection that keeps recent generations, Nix store optimisation, and pruning of dangling Docker images. This is delivered and deployed **first**, so the real free space on kaito is known before the repository is enabled.
- Add per-host scoped agenix secrets (repository password, REST credentials, S3 key) instead of the repository-wide `users ++ systems` default. Name the anonymous `systemN` host keys that are involved.
- Document the manual AWS setup (bucket, IAM policies) and a restore runbook, including offline storage of the recovery secrets. Those secrets are agenix-encrypted to the user's SSH key, which is itself inside the backups.

## Capabilities

### New Capabilities
- `service-backup-home`: Scheduled, encrypted restic backups of `/home` on workstation hosts to kaito and S3, with the personal-data selection policy, per-host credentials and no ability for clients to delete history.
- `service-backup-repository`: The kaito-hosted restic REST repository (mesh-only, append-only, private per host) and the server-side retention, pruning and checking of every host's kaito and S3 repositories.
- `service-backup-kaito-state`: Offsite S3 backup of kaito's `/var/lib` with consistent database dumps and exclusion of reproducible or bulky data.
- `system-nix-gc`: Daily automatic Nix garbage collection, store optimisation and dangling container image pruning, applied to kaito and importable by other hosts.

### Modified Capabilities
<!-- None: adding feature modules and imports to hosts does not change the requirements in nixos-configurations or flake-structure. -->

## Impact

- **Hosts**:
  - personal-casper, gaming-casper, technative-casper and sakura (all x86_64) import the home backup feature. On sakura this also covers `/home/antonia`; on technative-casper it covers `/home/lucak`.
  - kaito (x86_64) imports the repository server, the state backup and the cleanup feature.
  - server-casper (aarch64), neko, basic-home, nixhost and pixel-10a are not affected. The modules contain nothing architecture-specific.
- **NixOS modules**: dendritic and import-based, with no enable flags.
  - New category `modules/services/backup/`. A flake-level `casper.backup` registry, following the `casper.nebula` precedent, holds the repository server and S3 settings and the list of client hosts. Hosts register themselves next to their Nebula node.
  - The cleanup module lives in `modules/nix/`.
- **Secrets**: new `restic-*` entries in `secrets/secrets.nix` with narrow recipient lists. Renaming the `systemN` keys that are involved leaves their recipients unchanged.
- **External (manual, by the user)**: an S3 bucket in AWS account `980921758733`, IAM users and policies. The flake only consumes their access keys through agenix.
- **kaito resources**: repository disk usage must fit next to existing services on the single 440G filesystem. Sizes for hosts other than technative-casper (about 30G) are still unmeasured.
- **Home Manager**: not affected. Backups run as system services. The pending HM-to-dendritic migration is unaffected.
- **Related change**: `add-holyarrs` mentions local encrypted media backups under `/var/backups/media`. The state backup includes `/var/lib/holyarrs` and related service state but does not take over or duplicate that local repository.
- **Not in this change**: backing up `/srv` (Minecraft worlds), media libraries (`/mnt/audio`), server-casper/neko, and failure alerting. These are listed as follow-ups in the design.
