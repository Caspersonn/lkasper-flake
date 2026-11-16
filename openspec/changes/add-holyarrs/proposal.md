# Proposal

## Why

Replace the existing media experience with HolyArrs-managed acquisition, separate movie/TV and music applications, and music discovery beyond the owned library. The entire setup must be reproducible from this repository without configuration through web UIs; waiting for acquisition before first playback is acceptable.

## What Changes

- Add HolyArrs (request and library manager for movies, shows and music) to kaito as a pinned container, reachable only over the private Nebula mesh and Tailscale.
- Add Decypharr as HolyArrs' download client: it presents itself as qBittorrent, hands torrents to Real-Debrid and exposes the results as symlinks into a Real-Debrid mount, so nothing is stored or seeded locally.
- Add Jackett as HolyArrs' search source (Torznab), with the user-approved Knaben and The Pirate Bay sources and their music categories; Prowlarr is not used.
- Add a shared media layout under `/data` (debrid mount, symlink drop folder, `media/{movies,tv,music}` library) owned by a dedicated `media` identity, so all services see the same absolute paths.
- Replace first-run wizards and manual integration setup with declarative configuration and idempotent provisioning, including accounts, sources, downloaders, library paths and service connections.
- Keep non-secret service settings and client dotfiles in this repository. Use NixOS for shared services and Home Manager for user applications and their dotfiles; keep credentials encrypted with agenix and decrypt only at runtime.
- Store protected bootstrap inputs under `secrets/` and encrypted backups locally on kaito under `/var/backups/media` as approved by the user. Keep live databases under `/var/lib`; local backups do not provide recovery from server disk loss.
- Add an open-source music experience that discovers music outside the library, sends acquisition requests to HolyArrs, tracks availability and starts playback automatically when ready. The user approved reusing the existing paid Real-Debrid subscription for music acquisition; no additional music-app, streaming or VPN subscription and no YouTube fallback are required.
- Use HolyArrs → Decypharr → Real-Debrid for music as well as movies/TV. Do not add Transmission or a torrent VPN: torrent acquisition happens remotely, not on kaito. Real-Debrid still sees the connecting public IP; this protects against exposure to torrent peers, not against the provider.
- Use Jellyfin as the user-selected movie/TV playback application, separate from Soundspan. Deployment and playback remain unverified.
- Preserve Navidrome, AIOStreams and existing libraries until the replacement workflows have passed acceptance tests. Removal is gated on a verified migration, not performed just because new services start.
- Soundspan is the user-selected music application, conditional on verifying the required HolyArrs workflow. Its documented acquisition integration is Lidarr, not HolyArrs; implement the user-approved native HolyArrs provider against pinned source contracts and verify the complete workflow before rollout rather than assuming API compatibility.
- Comments in code are not needed.

## Capabilities

### New Capabilities
- `service-media-acquisition`: A declaratively configured private media pipeline, including separate playback experiences, music discovery-to-acquisition-to-playback and repository-managed client configuration.

### Modified Capabilities
<!-- None: adding modules to kaito does not change the requirements in nixos-configurations or flake-structure. -->

## Impact

- **Hosts**: acquisition and playback services target kaito (x86_64). Home Manager client configuration targets `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`. Other hosts and user profiles remain unaffected.
- **New NixOS modules** (dendritic, import-based, no enable flags), all under `modules/services/tools/`: `media-storage.nix`, `holyarrs.nix`, `decypharr.nix`, `jackett.nix`, `media-connections.nix` and `media-backup.nix`, imported only by kaito.
- **Home Manager**: client packages and supported dotfiles belong under `modules/users/shared/`, composed through the existing user modules. Server-owned `/var/lib` configuration remains under NixOS, not a user's home directory. No general Home Manager migration is included.
- **Dependencies**: Docker images `holyarrs/holyarrs` and `cy01/blackhole` (Decypharr), nixpkgs `jackett` and `restic`; existing Docker oci-containers backend on kaito.
- **Firewall**: new ports 6262 (HolyArrs), 8282 (Decypharr), 9117 (Jackett) opened only on the Nebula and Tailscale interfaces; nothing new on the LAN or the public nginx.
- **Storage**: use the existing Real-Debrid mount and symlink libraries for all media. Verify music imports and playback through those links; application databases, artwork and bounded caches remain local, not complete retained media copies.
- **Secrets**: replace UI-entered credentials and manual key copying with agenix-backed runtime provisioning and a reproducible recovery procedure. Plaintext secrets must not enter Git, Nix derivations or logs.
- **Readiness**: component provisioning tests cover Decypharr rendering, encrypted acquisition-state backup, real Jackett source configuration, HolyArrs owner/API bootstrap and native connection reconciliation. Actual Decypharr token-password login from HolyArrs is verified separately. Live acquisition, client configuration and playback acceptance remain open; nothing is deployed by these checks. Read-only host checks confirm the earlier acquisition baseline already exists on kaito, so rollout must preserve its current state rather than assume a fresh `/data` tree.
