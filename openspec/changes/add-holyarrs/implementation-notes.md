# Implementation notes: add-holyarrs

## Aurral/slskd selection, specification only (2026-11-17)

The user selected Aurral Flows + slskd for mixed-artist discovery using temporary full-song downloads, with liked flow tracks retained in the permanent library. Proposal, design, requirements and tasks now distinguish this direct Soulseek/local-audio music path from the unchanged Moonfin/HolyArrs/Real-Debrid video path. Prior Soundspan implementation and tests remain historical results; they do not verify Aurral.

The selection follows the upstream [Flows](https://docs.aurral.org/using/flows/), [slskd](https://docs.aurral.org/integrations/slskd/) and [Subsonic/Navidrome](https://docs.aurral.org/integrations/navidrome/) documentation inspected on 2026-11-17. Prepared flows contain full downloaded files; undownloaded recommendations may only offer previews. The documented favorite-to-library trigger is for clients connected to Aurral's Subsonic endpoint, not automatically Navidrome. Exact version contracts, unattended provisioning, storage limits, peer/share policy, clients, retention safety and real playback remain unverified under section 19.

No service implementation, host configuration, credentials or running environment were changed by this specification update. Soundspan and existing services/libraries remain in place. Deployment and removal require their separate approval gates. Comments in code are not needed.

## Soundspan client acquisition gates (2026-11-16)

The download availability response and job-creation preflight now include HolyArrs alongside the other providers. Regression tests cover availability and album submission with only HolyArrs configured, using Billie Eilish's `HIT ME HARD AND SOFT` as the request fixture. The targeted backend suites passed 88 tests, and the Python suite passed 119 tests. The kaito build passed at `/nix/store/ymwspplammkpijsg8nab5x7f5ni98cs7-nixos-system-kaito-26.05.20261015.26f4107`; the Soundspan VM passed at `/nix/store/hc7nqdb0aan10168vddw19drb9fv7lmq-vm-test-run-soundspan-provision`. Strict OpenSpec validation passed. Activation and live client-request/playback verification remain pending.

On kaito, the user's manual HolyArrs downloads imported `dont smile at me` (9/9 tracks) and `WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?` (14/14 tracks). The `my future` download required an import decision. HolyArrs had received no Soundspan asks at inspection time. These imports do not establish discovery, acquisition or playback of `BIRDS OF A FEATHER`, which belongs to `HIT ME HARD AND SOFT`; Soundspan library detection and playback remain unverified.

The earlier runtime deployment was activated: Soundspan's backend/frontend were active and the public-origin onboarding request returned HTTP 200 with the configured allow-origin header. The user confirmed music search after the Last.fm activation.

## Soundspan runtime paths and metadata availability (2026-11-16)

After the Last.fm activation, kaito returned its frontend in 0.013911 seconds and onboarding status in 0.004553 seconds. A direct MusicBrainz artist lookup returned HTTP 503 in 0.110845 seconds; backend logs also recorded recording-search HTTP 503 responses. These measurements do not measure authenticated artist/album page latency. No music symlinks were present under `/data/media/music`; discovery results alone do not establish playable media.

Backend logs additionally reported rejection of the public Soundspan origin and attempted transcode-cache creation under the read-only package path. A repository-managed environment file now overrides those generated persistent defaults with the public/loopback origin allowlist and `/var/cache/soundspan/transcodes`. Systemd owns the cache-directory lifecycle. The VM check passed at `/nix/store/0ck53zkdwcb58qv7k32am66dkb4xmgsm-vm-test-run-soundspan-provision`, verifying public-origin response headers and cache writability before and after activation. The kaito build passed at `/nix/store/fa0x1bdggnq73k6kac7cqlhqs9pqa8q8-nixos-system-kaito-26.05.20261015.26f4107`; the Python suite passed 119 tests and strict OpenSpec validation passed. Deployment verification for this runtime change is pending sudo activation on kaito; metadata loading and acquired-track playback remain open under task 17.2.

## Soundspan music discovery credential (2026-11-16)

Music discovery search uses Last.fm; podcast search uses iTunes without that credential. The Soundspan backend now includes the existing `music-lastfm` agenix secret as a second systemd environment file when declared. Neither credential values nor decrypted files enter the Nix store. A direct artist search using the encrypted repository credential returned Miles Davis, Miles Davis Quintet and Miles Davis Quartet. Deployed Soundspan search still requires verification after activation; this external API check does not establish album import or playback.

The kaito build passed at `/nix/store/jh6b56gyp0pf2ifp2y0nzc91qqsgl0vk-nixos-system-kaito-26.05.20261015.26f4107`; the configuration without agenix reused the passing Soundspan VM check `/nix/store/jn8sqsv877v43jkj8qvsrqd957798glq-vm-test-run-soundspan-provision`. The Python suite passed 119 tests. Activation requires sudo access on kaito.

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

## Linked music library scanning (2026-11-16)

Kaito's manual HolyArrs imports include HIT ME HARD AND SOFT (10 tracks),
WHEN WE ALL FALL ASLEEP, WHERE DO WE GO? (14 tracks), and dont smile at me
(9 tracks). These are library symlinks; Soundspan's scanner previously skipped
all symbolic links. The source patch now includes audio links whose targets are
regular files, retains their library paths, and excludes dangling and directory
links. A regression covers the linked BIRDS OF A FEATHER filename, a missing
target, a directory target and non-audio links.

Provisioning submits a library scan after settings reconciliation, accepting
only scan-cooldown HTTP 429 as a nonfatal response. The backend uses packaged
FFmpeg and a systemd-managed writable playlist log directory. Three backend
regression suites passed 126 tests; the Python suite passed 121 tests, including
scan submission, cooldown and failure handling. The VM creates a tagged FLAC
under `/data/debrid`, links it into `/data/media/music`, and verifies that the
startup scan indexes one track. It also verifies writable playlist logs and
preserved credentials across another activation. VM output:
`/nix/store/qsd1h391dzyvflfs2240v7f6skaaxlx3-vm-test-run-soundspan-provision`.
Kaito closure:
`/nix/store/2avh7jp7yyrj74hlgi8rkddz8x71z205-nixos-system-kaito-26.05.20261015.26f4107`.
Deployment verification, ongoing acquisition refresh and actual Billie Eilish
playback remain separate acceptance checks.

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
## Moonfin native HolyArrs integration

Moonbase `c6aad40f61a89be84a272329731b5b688eac8567` is packaged with a repository-managed native HolyArrs backend behind the official Moonfin request protocol. No Seerr service is deployed. The plugin supplies discovery, movie/show details, movie and whole-show/selected-season requests, request lists and counts. Unsupported operations return 501. Requests use the managed HolyArrs owner; restricted Jellyfin accounts are refused. The key is read from a systemd credential and never returned to the client.

The contract executable passed 45 assertions and the Python suite passed 121 tests. The final Jellyfin VM passed authorization, repeat activation, distinct absent/present TMDB identifiers and streaming of a linked video fixture (`/nix/store/k38q3lgh66zf2v7syihjx5rky4gvar0r-vm-test-run-jellyfin-provision`), including the paged provider lookup and request-count additions. Kaito closure `/nix/store/abdllz8vi36f08d55lgj0az4pvh8b4pg-nixos-system-kaito-26.05.20261015.26f4107` and all three selected Home Manager activation packages built; the server closure was copied but activation requires sudo on kaito. The official Moonfin 3.1.0 Linux client started under Xvfb and remained running until the 25-second smoke-test timeout. Its FHS package includes the shared libraries required by the official bundle, including libgbm. Request protocol source files were compared with the official 3.1.0 tag without differences.

The client is selected for Casper's gaming, personal and technative Home Manager profiles. Android and Android TV compatibility is based on the official 3.1.0 client protocol and release artifacts, not device testing. Existing client state is preserved; automatic server registration is not implemented. Production deployment, real movie/show request-to-playback and Android/TV execution remain open acceptance work.
# Aurral isolated bootstrap implementation (2026-11-17)

Search concurrency adjustment (2026-11-18): the user selected three search workers without upstream patches, then explicitly approved applying only the supported setting to the existing installation. `--worker-only` authenticates with the protected existing administrator seed and sends only `concurrency=3` to the supported worker-settings endpoint, verifying read-back. Incomplete onboarding and missing seeds are refused; application settings, flows, slskd credentials, service restarts and queue operations are excluded. All 177 Python tests pass with real Restic available, including the restricted endpoint boundary, repeat convergence, unrelated settings and credential preservation, invalid native limits, failed authentication and failed convergence. An isolated instance of the pinned official image passed a real API two-to-three update and repeated invocation with unchanged flow identities, enable flags and other worker settings. The immutable updater `/nix/store/njsw8bg389xzs9zhzkb6mr6npppqhxh7-aurral-worker-update` was built and copied to kaito; production application awaits the user's sudo command because unattended sudo requires a password. Six transfer slots and the absent speed cap remain unchanged. The full system built earlier, but two fresh VM runs failed on managed-flow loss after enabling the first flow while creating another; a 30-second visibility wait did not help. Clean local instances reproduced persisted whole-array overwrite races, and creating both recipes before enabling them still allowed a subsequent enable flag to revert. That unsuccessful experiment was removed. This separate fresh-bootstrap limitation remains open; the existing-instance update does not claim to fix it or complete full VM acceptance. No application API key was generated and no new upstream patch was applied.

Throughput adjustment (2026-11-18): live slskd options showed two transfer slots and a 2048 KiB/s aggregate cap; observed transfers reached approximately 2 MiB/s while more files waited locally. The user requested six simultaneous transfers and no speed cap. The renderer now sets six slots and omits `speed_limit`, using pinned slskd's native 2147483647 KiB/s default. Aurral search-worker concurrency, existing queues, credentials, retry policy and storage safeguards are unchanged. The ten-second capacity guard remains a polling threshold; uncapped transfers can increase overshoot. All 170 Python tests pass with real Restic available, including replacement of the old cap with stable credentials and repeated configuration convergence. VM `/nix/store/2cpnd4xffby3jgk0xgbjr53ig3jdwkxd-vm-test-run-aurral-flows-provision` passed, including runtime API assertions for six slots and the native speed-limit default. System `/nix/store/jg55d0rggn6g7banhgxhgsfk648iawir-nixos-system-kaito-26.05.20261015.26f4107` built, was copied to kaito and its activation executable was verified. Production activation and runtime read-back remain pending the user's sudo command. Strict OpenSpec validation and `git diff --check` pass.

Flow enablement verification (2026-11-18): all 169 Python tests and VM `/nix/store/qbk8ls8xpid6lgbbq716bva9l8hrpwwj-vm-test-run-aurral-flows-provision` passed, including fresh enabled managed flows and repeated provisioning/restart without duplicate recipes. System `/nix/store/ppy3gpwracr6j6bqg7sjnhjvs6n5d1a8-nixos-system-kaito-26.05.20261015.26f4107` built and was copied to kaito. This supersedes the pending VM/build statement below. Remote sudo still requires a password, so production activation and enabled-state read-back remain pending the user's activation command. Existing personal playlists and preview behavior are unchanged.

Preview/download investigation (2026-11-18): kaito's two managed recipes had `autoDownload=true` but remained disabled because provisioning never called the separate flow-enable endpoint. The correction declares enabled state, applies it after verified recipe settings, verifies read-back, and preserves unrelated playlists and already enabled flows without retriggering them. Regression tests model the upstream disabled-by-default behavior and cover disabled-flow repair, failed enabled-state convergence and refusing to enable an unconverged recipe. All 169 Python tests pass with real Restic available, strict OpenSpec validation passes, and the VM probe now requires both managed recipes to be enabled; the updated VM build and production activation remain pending. Read-only inspection also found real completed Soulseek downloads: Roadtrip is a 124.875-second FLAC and All I Want for Christmas Is You is a 241.507-second FLAC. These measurements establish full files, not authenticated client playback. The user's separate 90-track playlist had one completed, two downloading and 87 pending jobs at inspection; it is not reset by this correction. The user subsequently confirmed that downloads work and accepted 30-second discovery previews. Preview behavior is unchanged; automatic managed-flow enablement is a separate correction. Discovery previews and unfinished tracks must not be described as ready full-song playback.

Activation verified (2026-11-18): kaito runs `/nix/store/33qzkz7jxb4xa16w29ikbbks48ndw43i-nixos-system-kaito-26.05.20261015.26f4107`. Both new containers, provisioning, nginx, Navidrome, AIOStreams, Soundspan and Jellyfin are active; systemd reports no failed units. Aurral 2.13.0 reports onboarding complete and authentication required. slskd connected and logged in with the separate generated account. Certificate-validated HTTPS through nginx returns 200 for the application and 401 for anonymous settings access. Public DNS for Aurral still resolves to `77.175.230.128`, while kaito's current public address and the existing music services resolve to `83.83.71.166`; resolving the Aurral hostname explicitly to the current address returns HTTPS 200. DNS correction, real flow acquisition and device-client acceptance remain open. This supersedes the activation-pending statements below.

Deployment approval (2026-11-18): the user approved bringing the isolated stack onto kaito. The host now declares `aurral-flows`, connection with its separate generated Soulseek identity and HTTPS at `aurral.inspiravita.com`, whose DNS already resolves. Read-only preflight confirmed ports 3002/5032/50310 and all new state/library roots were unused, 136 GiB was available, and Octo/slskd and the existing media services were running. No old account, shares, containers or libraries are adopted. Inbound peer port 50310 remains closed. System `/nix/store/33qzkz7jxb4xa16w29ikbbks48ndw43i-nixos-system-kaito-26.05.20261015.26f4107` built successfully, its closure was copied to kaito and its activation executable was verified there. Remote passwordless sudo is unavailable; the user must set the system profile to this closure and activate it with sudo. The running system remains `/nix/store/hh59q4f05crwxjsphmqih7q0d939h8ms-nixos-system-kaito-26.05.20261015.26f4107`; production activation and live acquisition are not yet verified.

Additional local contracts (2026-11-18): real encoded-file quality checks and a stubbed, history-free Trending selection passed against the pinned image. Prepared blocked/failed jobs were visible through the authenticated API, anonymous listing/retry was rejected, an explicit failed-job retry returned pending, and all fallback sources remained disabled. Expanded VM coverage includes these contracts and the HTTPS readiness gate; no live Soulseek transfer or device-client acceptance is implied. Disk space fell to 2.3 GiB during concurrent test runs, so the older superseded VM build was cancelled before starting any further large builds.

The expanded VM reached the maintenance-lock contention fixture after passing HTTPS gating, quality selection, cleanup resumption and the existing retention/recovery checks. Its temporary lock-holder failed because the transient service could not resolve `sleep`; the fixture now uses absolute executable paths and a bounded 30-second lock wait. The build remains unverified until rerun. VM shutdown returned available local space to 11 GiB without garbage collection.

The corrected expanded VM passed as `/nix/store/1b46dljp654zwd3ny8bir501p5szqhds-vm-test-run-aurral-flows-provision`. It includes HTTPS provisioning gates, encoded-file quality and cold-start Trending contracts, authenticated waiting/failed/retry states, real FLAC retention and recovery, reference-aware cleanup service resumption, and maintenance-lock contention. This supersedes the pending expanded-VM statements below; live peer acquisition, desktop/Android client acceptance and kaito activation remain unverified.

Saved-playlist regression (2026-11-18): explicit Add to library, saving a prepared flow, concurrent favorite/flow deletion, deletion of the saved playlist and container restart preserved both full FLAC tracks and the favorite locally and in VM `/nix/store/8x08n9898zwx8pqa695mc0qj74ajp10y-vm-test-run-aurral-flows-provision`.

## Favorite persistence patch (2026-11-18)

A clean disposable test reproduced a pinned upstream defect: native flow cleanup kept the full audio, but the favorite vanished after restart because its identity depended on the removed flow. The source patch records a permanent-library-job alias internally and resolves it to the actual indexed library identity. It retains the existing client authorization checks and does not expose an additional Subsonic identifier type. The patched source is fetched by commit and hash, patched without fuzz and mounted read-only over the corresponding file in the pinned image.

The clean local regression and NixOS VM passed streaming two real two-second FLAC files, duplicate favorites, native flow deletion, verified removal of the unliked file, non-destructive unfavorite and favorite/full-file playback after container restart. VM `/nix/store/8x08n9898zwx8pqa695mc0qj74ajp10y-vm-test-run-aurral-flows-provision` also passed encrypted backup with a kept file still inside `_flows`, exclusion of the unkept file, verified staging restore, refusal to overwrite live state and clean installation into isolated disposable roots with stable credentials and resumed playback. Its capacity fixture exceeded an 8 MiB budget with 9 MiB of staging data: only the new slskd stopped, playback continued, and removal of the fixture allowed resumption. Reference-aware incomplete-transfer cleanup remains under verification. Nothing was activated on kaito.

The current Python suite passes 166 tests with real Restic available. Twelve new cleanup tests cover reference preservation, age and scan/deletion limits, linked files, busy-provider/application refusal, fixed-unit recovery, inactive downloader preservation and redirect refusal. Daily cleanup and backup/capacity serialization are implemented; the expanded service-level VM verification is pending.

The opt-in module uses pinned Aurral 2.13.0 and slskd 0.26.2 images in separate containers, state directories and ports; no host imports or running services have changed. The Python suite passes 154 tests, including protected administrator bootstrap, settings/recipe drift repair, credential rotation, malformed journal refusal, interrupted flow creation, unmanaged-state refusal, isolated slskd credential/configuration rendering, capacity pause/resume decisions and actual restic selection/restore with literal special-character filenames. Two repeated local runs against the official Aurral image converged without UI setup. The VM passed initial provisioning, repeat activation/container restart with stable credentials and flow identifiers, authenticated Subsonic access, private slskd administration and journal credential-redaction checks. Soulseek connectivity remained disabled. slskd's unconditional age-based file pruning is disabled to preserve active references. Real peer acquisition, client compatibility and production readiness remain unverified.
