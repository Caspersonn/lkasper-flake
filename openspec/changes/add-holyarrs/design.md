# Design

## Context

- kaito (x86_64, i3-1315U, 15 GB RAM, single NVMe with ~176 GB free) is a self-contained host in `modules/hosts/kaito/configuration.nix`; it already imports `docker` (oci-containers backend `docker`), `networking-nebula` (network `mesh`, kaito = `10.123.0.1`), `tailscale` and `secrets`.
- The NixOS firewall is global today; only `adguardhome.nix` scopes ports to an interface (`enp86s0`). Nebula's own firewall allows all inbound traffic.
- Existing container modules (`aiostreams.nix`, `twenty.nix`) publish ports through Docker. Docker-published ports are DNAT'ed in the `nat`/`FORWARD` chains and bypass the NixOS `INPUT` rules, so they cannot be limited per interface with `networking.firewall.interfaces`.
- HolyArrs has no published binaries and refuses to run as root outside a container; it ships as a `FROM scratch` image with a built-in healthcheck. Decypharr ships as the `cy01/blackhole` image with FUSE and rclone inside. Jackett is packaged in nixpkgs with a NixOS module. Neither HolyArrs nor Decypharr is in nixpkgs.
- HolyArrs only follows symlinks when `HOLYARRS_FOLLOW_LINKS=1` is set; it then places imported links in the library as links. Symlinks only resolve if every service sees the mount at the same absolute path.
- The four acquisition modules already exist. Historical build and VM results in `implementation-notes.md` verify that baseline, not declarative first-run provisioning or a complete playback stack.
- The confirmed workflow is discovery outside the owned music library, a HolyArrs acquisition request, a wait, and automatic playback. Music and movie/TV applications must be separate.

## Goals / Non-Goals

**Goals:**
- One shared `/data` tree with identical paths on the host and in every container, readable by the selected playback services.
- Private-only management interfaces enforced by the NixOS firewall, not by convention.
- No-clickops provisioning from repository-managed settings and protected runtime secrets, including on a fresh installation.
- Home Manager manages supported user application configuration and dotfiles; NixOS manages server services and their configuration.
- Preserve existing services and library data until the replacement passes end-to-end acceptance.
- Everything removable by dropping the imports from kaito.

**Non-Goals:**
- Removing existing libraries or services before replacement acceptance.
- Requiring YouTube or paid streaming as a substitute for music acquisition.
- qBittorrent + VPN, Usenet, Prowlarr, FlareSolverr.
- Reusable multi-host defaults; the modules are written for kaito's layout and are x86_64-tested only (both images also publish arm64, but server-casper is not a target).

## Decisions

### NixOS services and Home Manager dotfiles
Keep shared daemons, containers, mounts, firewall rules and service-owned `/var/lib` state in NixOS modules. Add supported client packages and non-secret dotfiles through `flake.modules.homeManager` under `modules/users/shared/`, composed into explicitly selected user profiles. `modules/users/shared/meridian.nix` demonstrates `xdg.configFile` management, and `modules/users/casper/home-manager.nix` composes shared modules.
Web applications may have no local dotfiles; their settings still belong in repository-managed server provisioning. Selected client profiles are `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`. Wire client imports only into those profiles, including their NixOS-integrated Home Manager equivalents; do not add unconditional client imports to the shared Casper module used by other hosts.
*Alternative:* move the entire stack into Home Manager. Not selected because shared mounts, system accounts, containers and firewall belong to the host lifecycle rather than a login profile.

### Declarative provisioning replaces first-run setup
Manage non-secret intent in Nix and keep secret inputs encrypted with agenix. Prefer supported configuration files and secret-file inputs. For API-only settings, use systemd-managed idempotent reconciliation with runtime credentials, readiness checks, bounded retries and explicit failures. Reconcile only owned settings; preserve library records, listening history and user activity.
Bootstrap must cover owner accounts and API credentials: a script requiring a key first created in a web UI does not meet the requirement. Verify every bootstrap mechanism against its pinned version. Render secret-bearing configuration outside the Nix store with restricted permissions, never into derivation arguments or logs. Rebuilds must converge managed settings without duplicating integrations.
*Alternatives:* manual wizards, manual API commands or SQLite edits. Not selected because they do not provide the required reproducible lifecycle.

### Implementation gates for the expanded scope
The requirements are confirmed, but the expanded implementation design is not ready. Resolve the acquisition and bootstrap design gates before applying the expanded stack. The approved custom integration may be designed during this investigation; its implementation and end-to-end verification follow concrete tasks, rather than being prerequisites for writing those tasks:

- Soundspan is selected by the user as the music application, conditional on verifying the required HolyArrs workflow. Jellyfin is selected for movie/TV playback. Client profiles are `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`.
- Verify discovery, request submission to HolyArrs, availability refresh and automatic first playback. Soundspan documents Lidarr integration; HolyArrs documents Sonarr/Radarr compatibility, not Lidarr compatibility. A native HolyArrs adapter may be needed; neither an adapter nor a turnkey integration has been verified.
- Select a subscription-free music acquisition source and establish its HolyArrs/downloader integration and storage policy. The existing paid Real-Debrid path remains the movie/TV baseline and does not establish subscription-free music acquisition. Do not assume music files can always remain remote symlinks.
- Verify unattended bootstrap, settings reconciliation and credential/key recovery for every selected service at its pinned version. Current HolyArrs documentation describes newer releases than the implemented `1.0.19`; documentation alone does not prove version support.

Acquisition and bootstrap choices are implementation blockers, not decisions deferred to deployment. Discovery and a revised concrete design must precede implementation of the expanded scope; full workflow verification is an acceptance gate after implementation. Comments in code are not needed.

### Soundspan integration investigation
Inspected Soundspan source revision `207d412ab380de7e4e0af11daecd6a2f82f86857`; this identifies the research snapshot, not a selected deployment version.

- [Soundspan integrations](https://soundspan.io/docs/integrations) documents Lidarr acquisition and import webhooks, not a HolyArrs connection. Its separate Soulseek path does not demonstrate acquisition through HolyArrs.
- At the inspected revision, `backend/src/services/lidarr/lidarrArtistCatalog.ts` calls `/api/v1/album?artistId=...` and posts `RefreshArtist` to `/api/v1/command`. `backend/src/services/lidarr/lidarrQueue.ts` relies on Lidarr queue/history schemas and the `AlbumSearch` command. These are protocol and data-model dependencies, not just a configurable server URL.
- [HolyArrs old-app API](https://docs.holyarrs.com/reference/old-app-api/) documents only Sonarr/Radarr compatibility. Pointing Soundspan's Lidarr setting at HolyArrs is not a verified solution.

The user approved building a custom Soundspan-to-HolyArrs integration. The required workflow has not passed an end-to-end test. Do not substitute Soundspan's direct downloader and silently bypass HolyArrs. Task 0.2 stays open, including availability refresh and automatic playback verification.

### Custom integration direction
Use a native HolyArrs acquisition provider in a repository-managed patch to pinned Soundspan source, rather than implementing a general Lidarr compatibility server. This avoids emulating Lidarr artist/catalogue/queue/history semantics and exposing its library-cleanup operations. This is the implementation direction, not an implemented or verified integration.

Inspected HolyArrs tag `1.0.19`, source revision `3a710bab9e157dc68385da4f3f7e96b957f6617e`, matching the existing container tag. Source inspection establishes these contracts; runtime and image/source correspondence still need testing:

- `app/backend/internal/requests/routes_asks.go` accepts `POST /api/v1/asks` with `{"kind":"artist","id":"mbid:<artist MBID>","albums":["<release-group MBID>"]}`. Always send a nonempty explicit album list: an empty list requests the whole artist. The response wraps the request in `ask`; duplicate requests can return HTTP 200 instead of 201.
- `GET /api/v1/asks/{id}` returns the request view directly. Request states include `asked`, `approved`, `turned_down` and `available`. HTTP 409 can include `title_id` and `ready` for an item already in the library; other conflicts must remain failures rather than being treated as success.
- `app/backend/internal/accounts/setup_owner.go` implements owner creation at `POST /api/v1/auth/setup`, establishes a setup session and rejects creation if an owner already exists. `routes.go` registers login, setup completion and API-key routes. This supports further unattended-bootstrap investigation but does not yet verify credentials, CSRF/session handling or key recovery. Keep a fresh service inaccessible to other clients until owner bootstrap succeeds, because the first caller can claim ownership.
- `app/backend/internal/downloads/routes_downloaders.go` lists Transmission among supported downloader kinds and supports music-specific categories. Its request handling does not establish a Soulseek integration.

At the inspected Soundspan revision, `downloadSourcePolicy.ts` restricts providers to `tidal`, `lidarr`, `soulseek` and `youtube`; `downloadDispatcher.ts` dispatches Lidarr through `simpleDownloadManager`. Add HolyArrs explicitly to provider selection, dispatch, persistent job reconciliation and the corresponding settings/UI types. Do not disguise it as Lidarr or inherit the legacy automatic fallback order. HolyArrs-only mode must fail visibly when unavailable rather than dispatch to another source.

Persist the HolyArrs request identifier with the Soundspan job and reconcile pending requests after restart. An `available` request is a trigger to refresh Soundspan's library, not proof that Soundspan can play it. Resolve imported albums by MusicBrainz identity, verify playable tracks, then notify the requesting client to start its explicitly requested playback. Background completion must not unexpectedly start unrelated sessions. Preserve a visible pending state while metadata, acquisition or import is incomplete; surface rejection and errors with retry. Verify bounded retry, duplicate submission, already-owned media, refresh failure and restart recovery in contract tests and a disposable-VM end-to-end test before enabling the provider on kaito.

### Music acquisition and VPN isolation
The user selected Transmission with Jackett music indexers and local completed files, then required VPN protection rather than exposing the host's public IP to peers. The inspected HolyArrs API supports Transmission; the complete acquisition path is not yet verified. Add the downloader alongside Decypharr without changing the movie/TV Real-Debrid path or silently using it as the sole music source.

Isolate Transmission's outbound traffic behind a VPN with a fail-closed kill switch. Block direct peer traffic during startup, tunnel loss, reconnect and restart; route DNS through the tunnel and prevent IPv6 bypass. Keep RPC access private and available only to required local integrations. Do not route unrelated host services through the torrent VPN. Provision tunnel settings and protected credentials declaratively, with no web setup. Test blocked egress without the tunnel and the observed exit IP with it before enabling acquisition. A VPN changes which IP peers see; the VPN provider can still observe the connecting host's IP.

VPN provider, supported tunnel configuration, specific indexers and retention/seeding policy remain unresolved. The music application and acquisition services must not require a subscription; any separate paid VPN requirement must be explicitly accepted rather than silently added.

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
Pinned `cy01/blackhole:v2.7.2`; `/var/lib/decypharr:/app` (it runs `chown -R` on `/app` at start, so it must not share that directory with anything). The baseline leaves the Real-Debrid key, login, mount type, `download_folder=/data/symlinks` and category to a first-run wizard. Replace that setup with verified unattended provisioning. First-start handling of environment overrides must be tested; do not assume environment variables alone bypass the wizard.

### Jackett via the NixOS module
`services.jackett.enable = true` with `openFirewall = false`; 9117 is opened on the mesh interfaces like the others. Declare the HolyArrs link to `http://127.0.0.1:9117` and local-network access in provisioning. Indexer definitions and categories must be reproducible without UI configuration; credentials are protected runtime inputs or generated persistent state.

### Credentials and recovery
Replace the original UI-only credential decision with agenix-backed runtime provisioning or protected automatic generation. Preserve service-generated keys and databases together and restore them through an automated recovery procedure. HolyArrs' actual key path is `/var/lib/holyarrs/holyarrs.key`; its own backup excludes that key, so application backups alone are insufficient. Supported bootstrap and recovery mechanisms remain gated on version-specific investigation.
*Alternative:* manual entry and copying keys into a password manager. Not selected because clean-machine setup and recovery would still depend on clickops.

## Risks / Trade-offs

- [HolyArrs with Decypharr is untested end to end; categories and magnet redirects may break grabs] → Test a cached movie and provision required categories declaratively; a different downloader requires a revised design, not a manual workaround.
- [HolyArrs may hash a whole file through the link on rename or delete (issue #158)] → Accept for the test; watch Real-Debrid traffic during renames.
- [Music availability varies by source] → Verify the subscription-free acquisition path with a real album; metadata discovery does not guarantee acquisition. Source changes must be repository-managed.
- [Public trackers behind Cloudflare need FlareSolverr] → Use indexers that work without it for the test; add FlareSolverr later if needed.
- [HolyArrs versions and APIs evolve] → Pin versions, change pins in Git, and retest bootstrap, integrations and recovery before rollout.
- [`SYS_ADMIN` + `/dev/fuse` widen the Decypharr container's privileges] → Only on kaito, only reachable over the mesh, image pinned.
- [`HOLYARRS_ALLOWED_HOSTS` value format is not documented in detail] → If the hostname is rejected, use `http://10.123.0.1:6262`, which works without it.
- [Fixed uid/gid 2000 could collide on kaito] → Check `getent passwd 2000` / `getent group 2000` on kaito before deploying.

## Migration Plan

1. Resolve the implementation gates and update the concrete design and application-specific tasks before implementation. Preserve historical baseline results separately from the new acceptance criteria.
2. Build affected NixOS and Home Manager configurations. Test unattended fresh installation and repeated activation in a disposable VM before touching kaito.
3. With explicit deployment approval, copy and activate the configuration on kaito; provisioning runs automatically after required secrets and services are ready. Running a deployment command is not web configuration.
4. Test a movie through playback and an unowned album through discovery, HolyArrs acquisition, availability refresh and automatic playback. Verify restart, mount-loss, rebuild and recovery behaviour.
5. Keep Navidrome, AIOStreams and original libraries available throughout migration. Decommission only after equivalent replacement workflows pass and removal is approved.
6. **Rollback:** activate the previous generation or remove newly introduced imports and rebuild, retaining state, keys and original media data. Do not delete state during rollback.

## Open Questions

- Whether the selected declarative indexer configuration requires FlareSolverr can be established during source testing; introduce it only through an updated design and repository-managed configuration.
