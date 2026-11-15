# Proposal

## Why

Replace the existing media experience with HolyArrs-managed acquisition, separate movie/TV and music applications, and music discovery beyond the owned library. The entire setup must be reproducible from this repository without configuration through web UIs; waiting for acquisition before first playback is acceptable.

## What Changes

- Add HolyArrs (request and library manager for movies, shows and music) to kaito as a pinned container, reachable only over the private Nebula mesh and Tailscale.
- Add Decypharr as HolyArrs' download client: it presents itself as qBittorrent, hands torrents to Real-Debrid and exposes the results as symlinks into a Real-Debrid mount, so nothing is stored or seeded locally.
- Add Jackett as HolyArrs' search source (Torznab), because it carries each site's music categories; Prowlarr is not used.
- Add a shared media layout under `/data` (debrid mount, symlink drop folder, `media/{movies,tv,music}` library) owned by a dedicated `media` identity, so all services see the same absolute paths.
- Replace first-run wizards and manual integration setup with declarative configuration and idempotent provisioning, including accounts, sources, downloaders, library paths and service connections.
- Keep non-secret service settings and client dotfiles in this repository. Use NixOS for shared services and Home Manager for user applications and their dotfiles; keep credentials encrypted with agenix and decrypt only at runtime.
- Add an open-source music experience that discovers music outside the library, sends acquisition requests to HolyArrs, tracks availability and starts playback automatically when ready. Music discovery, acquisition and playback must not require a paid subscription or YouTube fallback.
- Use Jellyfin as the user-selected movie/TV playback application, separate from Soundspan. Deployment and playback remain unverified.
- Preserve Navidrome, AIOStreams and existing libraries until the replacement workflows have passed acceptance tests. Removal is gated on a verified migration, not performed just because new services start.
- Soundspan is the user-selected music application, conditional on verifying the required HolyArrs workflow. Its documented acquisition integration is Lidarr, not HolyArrs; verify the integration before implementation and do not assume API compatibility.
- Comments in code are not needed.

## Capabilities

### New Capabilities
- `service-media-acquisition`: A declaratively configured private media pipeline, including separate playback experiences, music discovery-to-acquisition-to-playback and repository-managed client configuration.

### Modified Capabilities
<!-- None: adding modules to kaito does not change the requirements in nixos-configurations or flake-structure. -->

## Impact

- **Hosts**: acquisition and playback services target kaito (x86_64). Home Manager client configuration targets `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`. Other hosts and user profiles remain unaffected.
- **New NixOS modules** (dendritic, import-based, no enable flags), all under `modules/services/tools/`: `media-storage.nix`, `holyarrs.nix`, `decypharr.nix`, `jackett.nix`. kaito's import list in `modules/hosts/kaito/configuration.nix` gains these four.
- **Home Manager**: client packages and supported dotfiles belong under `modules/users/shared/`, composed through the existing user modules. Server-owned `/var/lib` configuration remains under NixOS, not a user's home directory. No general Home Manager migration is included.
- **Dependencies**: Docker images `holyarrs/holyarrs` and `cy01/blackhole` (Decypharr), nixpkgs `jackett`; existing Docker oci-containers backend on kaito.
- **Firewall**: new ports 6262 (HolyArrs), 8282 (Decypharr), 9117 (Jackett) opened only on the Nebula and Tailscale interfaces; nothing new on the LAN or the public nginx.
- **Storage**: the implemented acquisition baseline uses Real-Debrid symlinks. Subscription-free music acquisition is not yet selected; its storage requirements must be established before implementation rather than assuming no local media storage.
- **Secrets**: replace UI-entered credentials and manual key copying with agenix-backed runtime provisioning and a reproducible recovery procedure. Plaintext secrets must not enter Git, Nix derivations or logs.
- **Readiness**: existing modules and historical VM checks cover the acquisition baseline only. No-clickops provisioning, client selection and the complete playback stack remain unimplemented and unverified.
