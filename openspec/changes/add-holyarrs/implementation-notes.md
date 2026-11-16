# Implementation notes: add-holyarrs

## HolyArrs owner and API provisioning (2026-11-15)

`holyarrs.nix` runs the owner/API provisioner as the media identity after the
container starts. It keeps generated owner credentials in
`/var/lib/holyarrs/provision/owner.json` and its native API credential in
`api-key.json` alongside it, with directory mode 0700 and file mode 0600. The
existing encrypted HolyArrs-directory backup includes these files and the
application master key. Existing unmanaged owners or missing established
credentials require migration or restore; no password or owner reset is used.
An intent journal permits recovery of an interrupted one-time API-key response
without creating duplicate managed keys or revoking unrelated keys.

The fixed-output image pins HolyArrs 1.0.19 to registry digest
`sha256:0d82787b6bd274bd19b31adee9689f90e55d4c46a8194594deecfe02882d963d`.
The application binds `127.0.0.1:6263`. A systemd socket proxy exposes the
existing private port 6262 only after owner/API bootstrap succeeds, and stops
with the container. Local-network login bypass is disabled through the
supported API. Mesh/Tailscale firewall rules remain the access boundary; the
backend is never bound to a non-loopback address.

```sh
python3 -B -m unittest discover -s tests/media
python3 -B tests/media/holyarrs-container.py
nix build .#checks.x86_64-linux.holyarrs-provision --no-link
```

The Python suite passed 85 tests, including 23 HolyArrs cases. The standalone
container check uses fresh disposable state on a random loopback port, injects
a lost API-key response, verifies orphan revocation, stable credentials after
repeat provisioning and container restart, owner setup completion,
authenticated API access, unauthenticated refusal, healthcheck and log
redaction. It uses no Real-Debrid credential or production state. The tested
image ID is
`sha256:d85f5415c6603386e270a4dce65f120a1bb8d6708a710d50da57c708b4366174`.
Deleted API-key numeric IDs can be reused; the check verifies revocation using
the old key value rather than requiring a new numeric identifier.

The actual-image NixOS VM check passed at
`/nix/store/m3x5vrkiyy7lz17vis9csw06alg9awby-vm-test-run-holyarrs-provision`:
closed access before bootstrap, stable owner/key hashes across two activations,
corrupt-credential refusal and restored recovery, socket closure on container
stop, protected state and redacted logs. A separate client verifies trusted
access and untrusted-interface/backend refusal, including after firewall
reload. The Jackett and Decypharr/backup VM checks passed again; the latter
still substitutes application processes. The pure kaito build produced
`/nix/store/8a1ayam1f6w50cfj8dnc59if6k8f9r9v-nixos-system-kaito-26.05.20261015.26f4107`.

Library folders, source/downloader connections and complete recovery remain
open. Completing owner setup does not establish full-stack readiness or a
successful `doctor` result. Nothing has been deployed.

## Jackett source provisioning (2026-11-15)

Knaben and The Pirate Bay are repository-managed in
`modules/services/tools/media-provision/jackett-settings.json`. Jackett's
pre-start renderer generates protected API and administration credentials in
`/var/lib/jackett/.config/Jackett/provision-auth.json`; the existing encrypted
Jackett-state backup includes this file. No browser configuration is needed.
Existing unmanaged server state requires explicit migration; provisioning
refuses to replace its credentials. Unknown settings and other sources survive.
TPB uses its Audio Top100 feed for keyword-less music queries; keyworded
movie/TV searches still use their requested categories.

```sh
python3 -B -m unittest discover -s tests/media
nix build .#checks.x86_64-linux.jackett-provision --no-link
```

The Python suite passed 62 tests, including 13 Jackett cases. The actual packaged
Jackett 0.24.2586 passed a clean VM test at
`/nix/store/ggbbfjc59l3cy7sv08wf2cwfssgck5b1-vm-test-run-jackett-provision`:
both sources configured, authenticated Audio/music capabilities, invalid-key
refusal, stable configuration across two activations, refusal of corrupt
credential state, recovery and redacted logs. These checks make no external
tracker requests and do not establish live album availability or HolyArrs
search compatibility. Tasks 8.2 and 13.3 remain open. The pure kaito build
produced
`/nix/store/gqlcc80hh0xjdl4lzk1q5202y6087xvj-nixos-system-kaito-26.05.20261015.26f4107`;
nothing was deployed.

## Acquisition-state backup operations (2026-11-15)

The expanded no-clickops stack has not been deployed. The sections dated
2026-11-12 below describe the original acquisition baseline, not completion of
the playback stack or unattended recovery.

`media-backup.nix` declares a daily encrypted restic repository at
`/var/backups/media/restic`. Its password is generated once and enrolled as
`secrets/media-backup-password.age` for the owner and kaito; agenix and systemd
credentials provide it at runtime. Live databases stay under `/var/lib`.
Backups remain on kaito as requested and do not cover server disk loss.

The acquisition snapshot includes `/var/lib/{decypharr,holyarrs,jackett}` and
the actual HolyArrs master key. It excludes Decypharr's streaming cache.
Previously active state writers stop for the snapshot and resume in reverse
order, including after failure or interruption. Initially inactive services
stay inactive. Do not switch system generations or manually start a writer
while a snapshot is running. Only completed snapshots are promoted from the
pending tag for restore and retention; failed snapshots are not restore
candidates. Seven daily and four weekly snapshots are retained.

After deployment, these units provide operational backup and restore
verification without browser configuration or manual key copying:

```sh
sudo systemctl start media-state-backup
sudo systemctl start media-state-restore
```

Restore verification uses `/var/lib/media-restore/latest`, with root-only
access and content verification. It refuses an existing target and does not
overwrite live state. Installing recovered state on a clean machine, restoring
library symlinks, and adding consistent Soundspan/PostgreSQL and Jellyfin
backups remain tasks 12.3 and 12.4; task 8.5 remains open. No backups of the
original Navidrome library or AIOStreams deployment are introduced here.

The test VM uses dummy age-encrypted inputs, real restic and substituted
application processes. It exercises production credential/pre-start hooks and
backup services without contacting Real-Debrid or claiming actual media
playback. Verification commands:

```sh
python3 -B -m unittest discover -s tests/media
nix build .#checks.x86_64-linux.decypharr-provision --no-link
nix build .#nixosConfigurations.kaito.config.system.build.toplevel --no-link
openspec validate add-holyarrs --strict
```

The Python suite passed 49 tests. The expanded VM check passed at
`/nix/store/dkbvn1wiy94va0m2vjx9j812dd9mjh7w-vm-test-run-decypharr-provision`;
the pure kaito build produced
`/nix/store/5njipw7q97yllkgs4fs3aahrqnszyfs9-nixos-system-kaito-26.05.20261015.26f4107`.
The VM also verified exclusion of partial snapshots, wrong-password refusal
before stopping services, interrupted-backup cleanup and redacted logs. A
separate local round-trip used the actual enrolled backup password through
private pipes with fixture state, without creating a plaintext password file.
No production service state was read, restored or deployed for these tests.

## Group 1 (pre-flight on kaito): blocked (2026-11-12)

kaito was unreachable while this change was implemented: `ping 10.123.0.1`
lost every packet, Nebula handshakes to `77.175.230.128:4242` timed out and
the public vhosts did not answer. Tasks 1.1–1.3 stay open and must be done
before task 7.1. The configuration itself was checked instead:

- Nebula network `mesh` without `tun.device`, so the interface is `nebula.mesh`.
- `services.tailscale.interfaceName` is `tailscale0`.
- No user or group in kaito's configuration declares uid/gid 2000.
- No tmpfiles rule for `/data` exists yet.

## 6.1–6.3 Build and diff (2026-11-12)

- kaito toplevel built: `/nix/store/lvr3q4vajyfqz28251jh8r043qgc9p7x-nixos-system-kaito-26.05.20261015.26f4107`
  (only Jackett and the .NET runtime were fetched; nothing was compiled).
- The toplevel derivations of gaming-casper, personal-casper, sakura and
  technative-casper are identical before and after; only kaito changed.
- The diff adds no tokens, passwords or API keys and no `.age` file.

## Smoke test in the kaito test VM (2026-11-12)

Not a task in this change, but kaito was down and the project rule is to test
on a non-critical machine first. `nix run .#vm-kaito -- --reset --headless
--forward 6262:6262` (see the add-host-vm-testing change):

- `docker-decypharr`, `docker-holyarrs` and `jackett` all `active`; both
  containers `healthy` after pulling their images (about three minutes on a
  fresh disk). The only failed units were the expected secret/ACME ones.
- `media` is uid/gid 2000, casper is in group `media`. `/data` is root 0755,
  `/data/debrid` root 0755 (mount point), the other folders `media:media`
  `drwxrws---`.
- `docker inspect`: host network for both; Decypharr has `CAP_SYS_ADMIN`,
  `apparmor=unconfined`, `/dev/fuse` and `/data` `rshared`; HolyArrs has no
  extra capabilities and `/data` `rslave`.
- `holyarrs doctor`: 14 OK, 0 WARN, 0 FAIL (runs as 2000:2000, umask 0002,
  `/data/symlinks` writable, metadata server reachable).
- HolyArrs keeps its master key at **`/var/lib/holyarrs/holyarrs.key`** (the
  `/config` root), which is the file task 8.5 must back up.
- Decypharr writes a default `config.json` and `auth.json` on first start and
  sends `/` to `/setup`, so the wizard of task 8.1 is still shown.
- Mount propagation: a tmpfs mounted inside the Decypharr container at
  `/data/debrid` was visible on the host and inside HolyArrs' mount namespace
  (read through `/proc/<pid>/root`). After `systemctl restart
  docker-decypharr` the `ExecStopPost` lazy unmount removed it from both;
  `ExecStartPre` then reported "not mounted".
- Firewall: the forwarded port arrives on the VM's `eth0` and timed out from
  the workstation, so 6262 is closed outside the mesh interfaces even with
  `--network=host`. The `nixos-fw` chain only accepts 6262, 8282 and 9117 on
  `nebula.mesh` and `tailscale0`.
- `HOLYARRS_ALLOWED_HOSTS` could not be proven from inside the VM: requests
  from 127.0.0.1 were answered for any `Host` header (also `evil.example`).
  Task 7.3 covers it with a real mesh request to `http://kaito.mesh:6262`.
- HolyArrs logged "TMDB: Metadata server is down … context deadline exceeded"
  every two seconds for its Explore lists while `doctor` reported the
  metadata server reachable. This is on the HolyArrs side, not in this
  configuration; check whether it persists on kaito.

## HolyArrs library and connection reconciliation (2026-11-16)

`media-connections.nix` reconciles three library folders
(`/data/media/{movies,tv,music}`), the Knaben and The Pirate Bay Torznab
sources and the Decypharr downloader through HolyArrs' native API. It runs as a
root oneshot after the three services, reads their protected credentials from
systemd credentials, and keeps a journal with managed IDs and credential
digests (never values) in `/var/lib/holyarrs/provision/connections.json`.
Existing managed records are adopted by listing, not recreated; changed hosts,
kinds, paths or identities are refused instead of forwarding a secret.
Unrelated records and settings are preserved, and nothing is deleted.

Library health must be `ok`; a missing, read-only or copy-fallback folder
refuses reconciliation. The downloader uses username `media` with Decypharr's
persistent token as password, and declares the movie, TV and music categories
plus an identity path mapping. Source tests only fetch local Jackett
capabilities, so they do not prove live tracker search or album availability.

```sh
python3 -B -m unittest discover -s tests/media
nix build .#checks.x86_64-linux.media-connections .#checks.x86_64-linux.media-acquisition --no-link --json
```

The Python suite passed 100 tests, including 15 connection cases. The
`media-connections` VM uses an authenticated qBittorrent fixture and the actual
HolyArrs and Jackett processes; the `media-acquisition` VM additionally starts
the actual pinned Decypharr image with a dummy encrypted credential. Both ran
two activations and service restarts with stable folder, source and downloader
IDs and an unchanged journal hash, and recovered after a failed connection
attempt. The acquisition VM also verified the host-visible FUSE mount,
uid 2000 readability, a restored mount after a Decypharr restart and the local
`holyarrs doctor` library/downloads checks. The doctor metadata check cannot
reach `api.holyarrs.com` in the isolated VM.

Decypharr image testing exposed Hearsay peer discovery and publishing enabled
by default; `decypharr-settings.json` now disables it explicitly. The pinned
image manifest is `sha256:1fb75ea43e4f47b3f8c387178e880d79b1d73c7aab4ba6f7e1f4fa484711e450`.

`docker-decypharr` pre-start now assigns the unmounted `/data/debrid` underlay
to media at 2770 and refuses a symlink, and a bounded post-start check requires
a host-visible mount. The actual-container test also verifies HolyArrs
authenticating to Decypharr with the token as password, wizard bypass, explicit
music routing and stable auth/signing state across a restart.

The full check command produced kaito closure
`/nix/store/bamviyhg26znndm0c693iwnrq8jvi70l-nixos-system-kaito-26.05.20261015.26f4107`,
`media-connections` VM `/nix/store/cbyy01kyw1lp9z1fpp048l3vih90xng2-vm-test-run-media-connections`
and `media-acquisition` VM
`/nix/store/i7b7j12y326fkwr1kw4b4lqnydrrm8da-vm-test-run-media-acquisition`.
Nothing has been deployed. Live acquisition, Soundspan, Jellyfin, client
profiles and clean-machine recovery remain open.

## Jellyfin video provisioning (2026-11-16)

`jellyfin.nix` now enables the packaged Jellyfin 10.11.11 service, adds its user to the
`media` group and runs `jellyfin-media-provision` after the server. The provisioner in
`media-provision/jellyfin.py` uses the loopback API only, owns `admin.json` at mode 0600
inside `dataDir/provision` and reconciles the two video libraries. Jellyfin returns 404
for `POST Startup/User` until `GET Startup/User` has initialised the first user, so the
read is part of the sequence; a completed instance without the seed is refused rather
than reset.

`python3 -B -m unittest tests.media.test_jellyfin` passes 7 tests.
`nix build .#checks.x86_64-linux.jellyfin-provision .#nixosConfigurations.kaito.config.system.build.toplevel --no-link --json`
passed; the check starts the real server, completes setup without a wizard, verifies the
admin identity, both library paths and an unchanged seed hash across a second activation.
VM output `/nix/store/g486ch34qdqm8j67dc5qsi9r5nqpk67w-vm-test-run-jellyfin-provision`,
kaito closure `/nix/store/igl7h1iqixinr4x63g8l54cx3jr4sdas-nixos-system-kaito-26.05.20261015.26f4107`.
Nothing is deployed; playback, client access and backup coverage remain open.

## Clean-machine recovery (2026-11-16)

`backup.py` gained an `install` operation: it consumes `/var/lib/media-restore/latest`
(the staged restore target), refuses a 0700-nonconforming or symlinked staging tree and
any existing or symlinked destination, moves each staged path into place, verifies the
required files, applies ownership from the settings `owners` map and removes the staging
directory, rolling moves back on any failure. `media-backup.nix` declares the owner map
and a `media-state-install` oneshot. A `lib.mkIf` conditional must not be passed through
`builtins.toJSON` (it serialises as a literal `_type:if` object); owners are merged with
`lib.optionals` instead. `MEDIA_STATE_DEBUG=1` on the service prints the underlying
exception and traceback for diagnosis; production output stays redacted.

`python3 -B -m unittest discover -s tests/media` passes 124 tests, including five install
tests. The decypharr-provision VM now stops the writers, empties
`/var/lib/{decypharr,holyarrs,jackett}` (jackett user and group added to the VM) and runs
`media-state-install`: state lands with the declared owners, the staging directory is
removed and a second install is refused. VM output
`/nix/store/lrkzhajd7kznswrdp2r4z2hd675w2s01-vm-test-run-decypharr-provision`. Soundspan
and Jellyfin state are included in backup settings when their services exist; the
Soundspan database is dumped with `pg_dump --format=custom` before writers stop. Nothing
has been deployed.

## Full-stack backup coverage (2026-11-16)

`media-backup.nix` now extends the encrypted acquisition-state backup to the
playback services when the host imports them: `/var/lib/jellyfin` joins the
backup paths, `soundspan-backend`/`soundspan-frontend` join the quiesced writer
units, and a pre-backup `media-state-dump-soundspan` hook runs
`pg_dump --format=custom` of the Soundspan database into
`/var/backups/media/soundspan-dump` (directory owned postgres:postgres after the
traversal fix that made `/var/backups/media` 0755 while the restic repository
stays 0700). The staged-restore install requires the dump file, so a snapshot
without a complete database cannot be promoted. Service detection uses
`config.services.jellyfin.enable` and a `hasAttr` check for the Soundspan units
so hosts without them keep the acquisition-only settings; owners for the new
paths are merged with `lib.optionals` because `lib.mkIf` must never be passed
through `builtins.toJSON`.

`nix build .#checks.x86_64-linux.backup-coverage --no-link --json` passed with
output `/nix/store/7cf5i6rvdk7sxsd29iqc1sgxpqg1a2k0-vm-test-run-backup-coverage`.
The VM (all modules plus agenix fixture secrets, docker backend, redis on TCP
6379) verifies: both provisioning probes pass before backup, one snapshot
captures all five state trees plus the dump, staged restore installs them with
owners media:media / jellyfin:jellyfin / jackett:jackett and the dump owned
postgres:postgres, staging is consumed, a second install is refused, and the
restarted services return to a working state — media-connections re-reconciles
with the same IDs after `reset-failed` clears the start-limit, the Jellyfin
provision oneshot is started explicitly because `partOf` does not auto-restart a
stopped oneshot, and the restored `admin.json` hash is unchanged. Iteration
lessons: nixpkgs `wait_for_unit` takes no `state=` argument (use
`wait_until_succeeds "systemctl is-active ..."` for finished oneshots), the
backup quiesce does not auto-restart `partOf` provision oneshots, and start-limit
counting can latch a restart that arrives too quickly after a quiesce failure.
Nothing is deployed.
