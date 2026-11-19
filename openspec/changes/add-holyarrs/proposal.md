# Proposal

## Why

Provide separate movie/TV and music experiences: Moonfin with HolyArrs-managed video acquisition, and Aurral Flows with slskd for full-song music discovery beyond the owned library. Music discovery should offer rotating, mixed-artist playlists; only tracks the user chooses to keep become permanent library items. The entire setup must be reproducible from this repository without configuration through web UIs; preparing downloads before playback is acceptable.

## What Changes

- Following the user's 2026-11-19 replacement request, replace the active Jellyfin video service with self-hosted Remux and its integrated discovery/source-selection/playback experience. Preserve Jellyfin state and all media for rollback; the earlier Moonfin/Jellyfin requirements below are superseded for the selected video application. Reuse AIOStreams/Real-Debrid without enabling Remux's native P2P acquisition. Provision and test the new server and clients before claiming live readiness.

- Add HolyArrs (request and library manager for movies, shows and music) to kaito as a pinned container, reachable only over the private Nebula mesh and Tailscale.
- Add Decypharr as HolyArrs' download client: it presents itself as qBittorrent, hands torrents to Real-Debrid and exposes the results as symlinks into a Real-Debrid mount. This video acquisition path does not retain complete local files or seed locally; the separately selected Soulseek music path does download local files.
- Add Jackett as HolyArrs' search source (Torznab), with the user-approved Knaben and The Pirate Bay sources and their music categories; Prowlarr is not used.
- Add a shared media layout under `/data` (debrid mount, symlink drop folder, `media/{movies,tv,music}` library) owned by a dedicated `media` identity, so all services see the same absolute paths.
- Replace first-run wizards and manual integration setup with declarative configuration and idempotent provisioning, including accounts, sources, downloaders, library paths and service connections.
- Keep non-secret service settings and client dotfiles in this repository. Use NixOS for shared services and Home Manager for user applications and their dotfiles; keep credentials encrypted with agenix and decrypt only at runtime.
- Store protected bootstrap inputs under `secrets/` and encrypted backups locally on kaito under `/var/backups/media` as approved by the user. Keep live databases under `/var/lib`; local backups do not provide recovery from server disk loss.
- Select Aurral Flows + slskd for music, superseding Soundspan and the Real-Debrid-only music requirement. Scheduled flows discover tracks from multiple artists outside the owned library and download full audio into temporary flow storage before playback. This is a rotating, prepared-playlist experience, not guaranteed instantaneous or endless streaming; a 30-second preview does not satisfy acceptance.
- Use Aurral's Subsonic endpoint for the documented favorite-to-library workflow: favoriting a downloaded flow track keeps it permanently. Also support explicit Add to library. Artist favorites/follows inform discovery without implicitly downloading an entire discography. Verify exact behavior at the selected pinned version.
- Preserve Navidrome as an optional playback server and existing library service. Clients using Aurral's Subsonic endpoint receive its documented favorite-to-library behavior; do not assume that favoriting in a client connected directly to Navidrome triggers the same action. Choose and verify supported Linux/Android clients during implementation.
- Keep Moonfin → Moonbase → HolyArrs → Decypharr → Real-Debrid for movies/TV. Music uses direct Soulseek transfers through slskd, with local temporary and permanent audio files; peers can see kaito's connecting public IP. This does not introduce a torrent client, require a new paid subscription or promise VPN-free anonymity. YouTube and other acquisition fallbacks are not part of the selected configuration.
- Use Moonfin as the movie/TV client on Linux, Android and Android/Google TV, with Jellyfin serving playback. A pinned Moonbase plugin implements the approved native HolyArrs backend behind the official client's request interface, without adding Seerr. Discovery, requests and playback remain in the same client; end-to-end acceptance remains open.
- Preserve Soundspan, Navidrome, AIOStreams and existing libraries until the replacement workflows have passed acceptance tests and removal is explicitly approved. Existing Soundspan patches and tests remain implementation history, not evidence that the new Aurral workflow is delivered.
- Define Aurral/slskd accounts, credentials, shared paths, quality policy, flow recipes, schedules, automatic downloads, favorite retention, storage limits and recovery declaratively. Pin versions and verify supported bootstrap/settings contracts before implementation; this selection authorizes a specification update, not immediate replacement or deployment.
- Comments in code are not needed.

## Capabilities

### New Capabilities
- `service-media-acquisition`: Declarative video acquisition and separate music discovery, including temporary full-song flows, favorite-to-permanent-library retention and repository-managed service/client configuration.

### Modified Capabilities
<!-- None: adding modules to kaito does not change the requirements in nixos-configurations or flake-structure. -->

## Impact

- **Hosts**: acquisition and playback services target kaito (x86_64). Home Manager client configuration targets `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`. Other hosts and user profiles remain unaffected.
- **NixOS modules** (dendritic, import-based, no enable flags), under `modules/services/tools/`: existing acquisition/storage/backup modules plus Aurral and slskd service composition targeting kaito. Inspect existing Aurral/slskd modules and state before adapting them; do not reset an earlier installation.
- **Home Manager**: client packages and supported dotfiles belong under `modules/users/shared/`, composed through the existing user modules. Server-owned `/var/lib` configuration remains under NixOS, not a user's home directory. No general Home Manager migration is included.
- **Dependencies**: Existing HolyArrs/Decypharr/Jackett/restic and Jellyfin/Moonbase/Moonfin, plus pinned Aurral and slskd. No Seerr, Lidarr, paid streaming service or additional downloader fallback is required for the selected music workflow.
- **Firewall**: HolyArrs, Decypharr and Jackett retain mesh-only access. Keep slskd administration private; define Aurral's authenticated client access and Soulseek peer-listening policy separately before rollout. Do not expose existing libraries as Soulseek shares implicitly.
- **Storage**: Preserve existing Real-Debrid links and libraries. Add isolated local Aurral library/`_flows` and slskd staging paths with identical service-visible paths, bounded temporary storage and cleanup that cannot remove retained tracks or existing libraries. Extend encrypted state recovery to Aurral/slskd and define protection for permanent local music; temporary flow files may be regenerated.
- **Secrets**: replace UI-entered credentials and manual key copying with agenix-backed runtime provisioning and a reproducible recovery procedure. Plaintext secrets must not enter Git, Nix derivations or logs.
- **Readiness**: component provisioning tests cover Decypharr rendering, encrypted acquisition-state backup, real Jackett source configuration, HolyArrs owner/API bootstrap and native connection reconciliation. Actual Decypharr token-password login from HolyArrs is verified separately. Live acquisition, client configuration and playback acceptance remain open; nothing is deployed by these checks. Read-only host checks confirm the earlier acquisition baseline already exists on kaito, so rollout must preserve its current state rather than assume a fresh `/data` tree.
