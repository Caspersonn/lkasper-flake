# Design

## Context

- kaito (x86_64, i3-1315U, 15 GB RAM, single NVMe with ~176 GB free) is a self-contained host in `modules/hosts/kaito/configuration.nix`; it already imports `docker` (oci-containers backend `docker`), `networking-nebula` (network `mesh`, kaito = `10.123.0.1`), `tailscale` and `secrets`.
- The NixOS firewall is global today; only `adguardhome.nix` scopes ports to an interface (`enp86s0`). Nebula's own firewall allows all inbound traffic.
- Existing container modules (`aiostreams.nix`, `twenty.nix`) publish ports through Docker. Docker-published ports are DNAT'ed in the `nat`/`FORWARD` chains and bypass the NixOS `INPUT` rules, so they cannot be limited per interface with `networking.firewall.interfaces`.
- HolyArrs has no published binaries and refuses to run as root outside a container; it ships as a `FROM scratch` image with a built-in healthcheck. Decypharr ships as the `cy01/blackhole` image with FUSE and rclone inside. Jackett is packaged in nixpkgs with a NixOS module. Neither HolyArrs nor Decypharr is in nixpkgs.
- HolyArrs only follows symlinks when `HOLYARRS_FOLLOW_LINKS=1` is set; it then places imported links in the library as links. Symlinks only resolve if every service sees the mount at the same absolute path.

## Goals / Non-Goals

**Goals:**
- One shared `/data` tree with identical paths on the host and in every container, ready for a media server to read later.
- Private-only management interfaces enforced by the NixOS firewall, not by convention.
- Zero secrets in the repository; all credentials entered through the services' UIs.
- Everything removable by dropping the imports from kaito.

**Non-Goals:**
- Jellyfin, client apps, or any playback path (follow-up change).
- Removing Navidrome, AIOStreams or the `aiostreams_env` secret (follow-up change).
- qBittorrent + VPN, Usenet, Prowlarr, FlareSolverr.
- Reusable multi-host defaults; the modules are written for kaito's layout and are x86_64-tested only (both images also publish arm64, but server-casper is not a target).

## Decisions

### Four flat modules under `modules/services/tools/`
`media-storage.nix`, `holyarrs.nix`, `decypharr.nix`, `jackett.nix`, each `{ inputs, ... }: { flake.modules.nixos.<name> = ...; }`, imported explicitly by kaito. Keeping the downloader separate lets a later qBittorrent + VPN module replace Decypharr without touching HolyArrs.
*Alternative:* one `holyarrs.nix` holding the whole stack. Rejected: harder to swap parts, and no existing module in `modules/services` imports another one, so cross-module imports would be a new pattern.

### Containers use host networking
Both containers run with `--network=host` and no `ports`. The NixOS firewall then governs 6262 and 8282 like any host service, and HolyArrs reaches Jackett (`127.0.0.1:9117`) and Decypharr (`127.0.0.1:8282`) over loopback.
Ports are opened only via `networking.firewall.interfaces."nebula.mesh"` and `networking.firewall.interfaces.${config.services.tailscale.interfaceName}`; `nebula.mesh` is the default tun name for network `mesh` and is checked on kaito before deploying.
*Alternatives:* publish on `127.0.0.1` and add an nginx listener on the mesh address (extra moving part, nginx needs the Nebula IP up before it starts); publish on `10.123.0.1:6262` (Docker fails to start the container if Nebula is not up yet, and does nothing for Tailscale); bridge network with `host.docker.internal` (Jackett would have to listen on the Docker bridge).

### Decypharr mounts Real-Debrid itself and propagates it to the host
Decypharr uses its built-in `dfs` FUSE mount at `/data/debrid`, with `/dev/fuse`, `SYS_ADMIN` and the host's `/data` bound as `/data:/data:rshared`, so the mount appears on the host. HolyArrs binds `/data:/data:rslave` so it sees the mount even if it started first. `allow_other` is switched on in Decypharr so other uids (later Jellyfin) can read it.
The Docker unit gets a lazy unmount of `/data/debrid` before start and after stop, so a crashed container (or kaito losing power) does not leave a dead "Transport endpoint is not connected" mount behind.
*Alternatives:* a host-side rclone mount of Decypharr's WebDAV (`external_rclone`) — removes FUSE from the container but adds an rclone unit, RC credentials and an unverified path contract; Decypharr's NFS server — another daemon and mount unit for no gain in a test setup.

### One `media` identity owns `/data`
`media-storage.nix` creates a `media` system user and group with a fixed uid/gid (2000), passed to both containers as `PUID`/`PGID` with `UMASK=002`, and adds `casper` to the group. `/data` itself is `root:root 0755` (tmpfiles refuses service-owned children under a non-root parent, as in `slskd.nix`); `/data/{symlinks,media,media/movies,media/tv,media/music}` are `media:media 2770` and `/data/debrid` is an empty mount point.
*Alternative:* separate users per container in a shared group. Rejected for now: both write the same tree and HolyArrs never needs to be isolated from Decypharr's files; Jellyfin will join the group later.

### HolyArrs settings that matter
Pinned `holyarrs/holyarrs:1.0.19`; `/var/lib/holyarrs:/config`; environment `PUID`, `PGID`, `UMASK`, `TZ` (from `config.time.timeZone`), `HOLYARRS_FOLLOW_LINKS=1`, `HOLYARRS_SAVE_PATH=/data/symlinks`, and `HOLYARRS_ALLOWED_HOSTS` with `kaito.mesh` so the mesh hostname is accepted (IPs are allowed by default). The systemd unit is ordered after Decypharr's but does not require it, so a Decypharr restart does not take HolyArrs down.

### Decypharr settings that matter
Pinned `cy01/blackhole:v2.7.2`; `/var/lib/decypharr:/app` (it runs `chown -R` on `/app` at start, so it must not share that directory with anything). The Real-Debrid key, login, mount type, `download_folder=/data/symlinks` and the HolyArrs category are set in its first-run wizard. Environment overrides are deliberately not used: they would be written into `config.json` anyway and the first start ignores them.

### Jackett via the NixOS module
`services.jackett.enable = true` with `openFirewall = false`; 9117 is opened on the mesh interfaces like the others. Linked in HolyArrs as `http://127.0.0.1:9117` with "Reach the local network" on. Jackett keeps its API key and indexer logins in `/var/lib/jackett`.

### Credentials stay in state directories
No agenix secrets are added. The Real-Debrid token lives in Decypharr's `config.json` (0600), HolyArrs' owner password and `holyarrs.key` in `/var/lib/holyarrs`, Jackett's key in `/var/lib/jackett`. `holyarrs.key` is copied into the password manager once, because HolyArrs' own backups exclude it.
*Alternative:* agenix + `FILE__`/env overrides. Rejected for this change: the values are generated or entered interactively, and Decypharr would persist them in its own config regardless.

## Risks / Trade-offs

- [HolyArrs with Decypharr is untested; category creation and magnet redirects may break grabs] → Test one cached movie before anything else; if it fails, add the HolyArrs category in Decypharr by hand; the fallback is a qBittorrent + VPN module in a separate change.
- [HolyArrs may hash a whole file through the link on rename or delete (issue #158)] → Accept for the test; watch Real-Debrid traffic during renames.
- [Music torrents are often not cached on Real-Debrid and public trackers are thin on music] → Uncached grabs still complete, just slower; private trackers or Usenet can be added later in the Jackett UI without code changes.
- [Public trackers behind Cloudflare need FlareSolverr] → Use indexers that work without it for the test; add FlareSolverr later if needed.
- [Young, single-maintainer HolyArrs with releases every few hours] → Pinned version, manual upgrades, `/var/lib/holyarrs` on local disk and `holyarrs.key` saved elsewhere.
- [`SYS_ADMIN` + `/dev/fuse` widen the Decypharr container's privileges] → Only on kaito, only reachable over the mesh, image pinned.
- [`HOLYARRS_ALLOWED_HOSTS` value format is not documented in detail] → If the hostname is rejected, use `http://10.123.0.1:6262`, which works without it.
- [Fixed uid/gid 2000 could collide on kaito] → Check `getent passwd 2000` / `getent group 2000` on kaito before deploying.

## Migration Plan

1. Build kaito's toplevel locally and review the diff; nothing is pushed or deployed without the user's go-ahead.
2. Push and build/copy to kaito; activate by hand (`switch-to-configuration switch` with sudo), since remote sudo needs a password.
3. Configure in order: Decypharr wizard → Jackett indexers → HolyArrs owner, library folders, Jackett link, downloader link.
4. Test: one cached movie end to end, then one album.
5. **Rollback:** remove the four imports from kaito and rebuild (or boot the previous generation). `/var/lib/{holyarrs,decypharr,jackett}` and `/data` remain on disk and can be deleted by hand; no other service is touched.

## Open Questions

- Whether FlareSolverr is needed depends on which indexers the user picks in Jackett.
- Where to back up `/var/lib/holyarrs` beyond the manual `holyarrs.key` copy (kaito has no backup job yet).
