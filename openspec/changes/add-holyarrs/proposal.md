# Proposal

## Why

Stremio (via AIOStreams) and Navidrome on kaito are being phased out in favour of one library that fills itself: HolyArrs finds and grabs movies, shows and music, and a media server later serves that library to every client. This first step stands up the acquisition side on kaito so it can be tested against the existing Real-Debrid account before anything is removed.

## What Changes

- Add HolyArrs (request and library manager for movies, shows and music) to kaito as a pinned container, reachable only over the private Nebula mesh and Tailscale.
- Add Decypharr as HolyArrs' download client: it presents itself as qBittorrent, hands torrents to Real-Debrid and exposes the results as symlinks into a Real-Debrid mount, so nothing is stored or seeded locally.
- Add Jackett as HolyArrs' search source (Torznab), because it carries each site's music categories; Prowlarr is not used.
- Add a shared media layout under `/data` (debrid mount, symlink drop folder, `media/{movies,tv,music}` library) owned by a dedicated `media` identity, so all services see the same absolute paths.
- Credentials (Real-Debrid token, HolyArrs owner password, Jackett API key) are entered in the web UIs and stay in each service's state directory; nothing secret enters the repository.
- Navidrome and AIOStreams keep running untouched; their removal, Jellyfin as the playback server and client apps are follow-up changes.

## Capabilities

### New Capabilities
- `service-media-acquisition`: A private, self-hosted pipeline on kaito that searches sources, acquires movies, shows and music through Real-Debrid and organises them into a shared library on disk.

### Modified Capabilities
<!-- None: adding modules to kaito does not change the requirements in nixos-configurations or flake-structure. -->

## Impact

- **Hosts**: only kaito (x86_64 server) imports the new modules. gaming-casper, personal-casper, technative-casper and server-casper are unaffected; the modules are not imported there and nothing in shared modules changes.
- **New NixOS modules** (dendritic, import-based, no enable flags), all under `modules/services/tools/`: `media-storage.nix`, `holyarrs.nix`, `decypharr.nix`, `jackett.nix`. kaito's import list in `modules/hosts/kaito/configuration.nix` gains these four.
- **Home-manager**: not affected; no client apps in this change.
- **Dependencies**: Docker images `holyarrs/holyarrs` and `cy01/blackhole` (Decypharr), nixpkgs `jackett`; existing Docker oci-containers backend on kaito.
- **Firewall**: new ports 6262 (HolyArrs), 8282 (Decypharr), 9117 (Jackett) opened only on the Nebula and Tailscale interfaces; nothing new on the LAN or the public nginx.
- **Storage**: library content lives on Real-Debrid via the mount; local disk holds only state, symlinks and small metadata. The 176 GB free on the NVMe is not consumed by media.
- **Secrets**: none added to agenix in this change. HolyArrs' `holyarrs.key` must be backed up by hand.
