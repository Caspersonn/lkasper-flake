# Spec Delta

## Purpose

Provides a declarative, private media pipeline on kaito with separate movie/TV and music applications, music discovery outside the owned library, and automated acquisition through HolyArrs before playback.

## ADDED Requirements

### Requirement: Delivered as importable NixOS modules
The pipeline SHALL be delivered as NixOS modules under `modules/services/tools/` (`media-storage`, `holyarrs`, `decypharr`, `jackett`, `media-connections`, `media-backup`), enabled solely by importing them into a host. No other host than kaito SHALL import them.

#### Scenario: Only kaito changes
- **WHEN** every `nixosConfigurations` output is evaluated after the change
- **THEN** only kaito's system closure contains the acquisition services, and hosts without an explicitly selected client profile remain unchanged

#### Scenario: Pure evaluation
- **WHEN** `nix build .#nixosConfigurations.kaito.config.system.build.toplevel` runs
- **THEN** the build succeeds without `--impure` and without any secret being present in the Nix store

### Requirement: Management interfaces are private
HolyArrs (port 6262), Decypharr (port 8282) and Jackett (port 9117) SHALL be reachable only from the Nebula mesh and Tailscale interfaces and from kaito itself. They SHALL NOT be reachable from the LAN or the internet, and SHALL NOT be published through the public nginx.

#### Scenario: Reachable over the mesh
- **WHEN** a mesh member opens `http://kaito.mesh:6262`, `http://kaito.mesh:8282` or `http://kaito.mesh:9117`
- **THEN** the respective web interface loads

#### Scenario: Blocked on the LAN
- **WHEN** a LAN device connects to kaito's LAN address on port 6262, 8282 or 9117
- **THEN** the connection is refused or dropped

#### Scenario: No public virtual host
- **WHEN** the kaito nginx configuration is inspected
- **THEN** it contains no virtual host for HolyArrs, Decypharr or Jackett

#### Scenario: Owner bootstrap is incomplete or fails
- **WHEN** HolyArrs starts before its managed owner and API access have been established, or provisioning refuses existing state
- **THEN** only its loopback backend is reachable and its mesh-facing management socket remains closed, preventing another client from claiming the owner

### Requirement: Reproducible service versions
HolyArrs and Decypharr SHALL run from explicitly pinned image versions; floating tags such as `latest` SHALL NOT be used. Upgrades SHALL happen only by changing the pinned version in the repository.

#### Scenario: Pinned images
- **WHEN** the running containers on kaito are listed
- **THEN** HolyArrs runs `holyarrs/holyarrs` at the pinned version and Decypharr runs `cy01/blackhole` at the pinned version

### Requirement: State survives restarts and rebuilds
Each service's configuration, database and credentials SHALL persist on kaito's local disk across service restarts, container re-creation, NixOS rebuilds and reboots.

#### Scenario: Container re-created
- **WHEN** a HolyArrs or Decypharr container is removed and started again by a rebuild
- **THEN** users, linked downloader, linked sources and library settings are still present

### Requirement: Shared library layout
The services SHALL share one tree under `/data`, visible at identical absolute paths on the host and inside every container: `/data/debrid` (Real-Debrid mount), `/data/symlinks` (downloader drop folder) and `/data/media/movies`, `/data/media/tv`, `/data/media/music` (library). Files created there SHALL be group-writable by a shared `media` group.

#### Scenario: Paths agree everywhere
- **WHEN** a symlink under `/data/symlinks` or `/data/media` is resolved on the host, in HolyArrs or in Decypharr
- **THEN** it resolves to the same file under `/data/debrid`

#### Scenario: Group access
- **WHEN** a file is created under `/data/media` by HolyArrs
- **THEN** it belongs to group `media` and is writable by that group

### Requirement: All media acquisition uses the existing debrid service
Movie, show and music releases SHALL be acquired through HolyArrs and Decypharr using the existing paid Real-Debrid service and exposed as symlinks into its mount, without retained full local media copies or seeding on kaito. No local torrent client or additional VPN service SHALL be introduced for this pipeline. Application state, artwork and bounded operational caches MAY remain local.

Decypharr's Hearsay peer discovery and publishing SHALL be explicitly disabled; remote acquisition SHALL NOT implicitly enable an additional peer network on kaito.

#### Scenario: Grab a cached movie
- **WHEN** HolyArrs grabs a release that Real-Debrid has cached
- **THEN** the item appears under `/data/symlinks` as a symlink into `/data/debrid` and no torrent traffic leaves kaito

#### Scenario: Mount unavailable
- **WHEN** the Real-Debrid mount is not available
- **THEN** imports fail visibly in HolyArrs instead of writing media to local disk

#### Scenario: Music acquisition without local torrent peers
- **WHEN** a music release is acquired or Real-Debrid cannot fetch it
- **THEN** kaito does not join a torrent swarm or fall back to a local torrent client, and failure is shown if remote acquisition cannot complete

### Requirement: Imports land in the library as links
HolyArrs SHALL accept symlinked downloads and preserve links when importing them into the library, named by its own naming scheme (music as `Artist/Album (Year)/NN - Title.ext`). Playback services SHALL read these links through the shared mount without requiring complete retained local copies.

#### Scenario: Import a movie
- **WHEN** a grabbed movie finishes in the downloader
- **THEN** HolyArrs places it under `/data/media/movies` as a link that plays the Real-Debrid file

#### Scenario: Import an album
- **WHEN** the owner adds an artist, marks an album to keep up to date, and a matching release is grabbed
- **THEN** the album's tracks appear under `/data/media/music/<Artist>/<Album> (<Year>)/` as links

### Requirement: Search sources include music
HolyArrs SHALL search the user-selected Knaben and The Pirate Bay sources through Jackett's Torznab feeds, including each site's music categories. Source configuration SHALL be repository-managed without requiring tracker accounts or browser setup.

#### Scenario: Music search returns releases
- **WHEN** the owner runs a manual search for an album in HolyArrs
- **THEN** results from the Jackett-linked sites are listed

### Requirement: Secrets are provisioned at runtime
Credentials, API keys and recoverable encryption keys SHALL be provisioned without web UI setup through agenix-encrypted inputs or automated generation and protected persistence. Plaintext secret values SHALL NOT enter Git, the Nix store or logs. Recovery SHALL NOT depend on manually copying HolyArrs' master key from its web deployment.

#### Scenario: Repository scan
- **WHEN** the repository, evaluated derivations and provisioning logs are inspected
- **THEN** plaintext credentials and keys are absent, while any repository-managed secret inputs are encrypted

#### Scenario: Restore encrypted state
- **WHEN** service state is restored using the documented automated recovery procedure and protected key material
- **THEN** the services can decrypt their stored credentials without manual key copying or account recreation

### Requirement: Encrypted local state backups
Protected repository-managed bootstrap state SHALL be stored encrypted under `secrets/`. Mutable databases SHALL remain in service-owned runtime directories. Backups SHALL be encrypted and stored on kaito under `/var/backups/media` until a different destination is approved. Snapshots SHALL preserve service state and its associated encryption/authentication keys consistently. Same-server backup storage SHALL NOT be represented as protection against server disk loss.

#### Scenario: Consistent acquisition-state snapshot
- **WHEN** the scheduled acquisition backup runs
- **THEN** state writers are stopped for the snapshot, the actual HolyArrs master key is included with its state, and previously active services resume even if backup fails

#### Scenario: Restore verification without overwriting live state
- **WHEN** an encrypted backup is restored for verification
- **THEN** the restored state is verified in a protected staging directory and an existing nonempty target is refused

### Requirement: Existing services are unaffected
Navidrome, AIOStreams and all other kaito services SHALL keep running unchanged while this pipeline is introduced.

#### Scenario: After deployment
- **WHEN** the change is activated on kaito
- **THEN** Navidrome and AIOStreams still serve their existing virtual hosts and libraries

### Requirement: No-clickops configuration
Accounts, indexers, downloader settings, library paths, service connections and required client settings SHALL be defined in this repository and applied without setup wizards, browser configuration, manual API calls or direct database editing. Provisioning SHALL be idempotent and preserve user library state. Ordinary discovery, playback and library requests are user activity, not configuration.

#### Scenario: Fresh installation
- **WHEN** the declared configuration is activated on a clean test machine with required runtime secrets available
- **THEN** the stack is ready for discovery, acquisition and playback without opening a setup wizard or entering settings in a UI

#### Scenario: Repeated activation
- **WHEN** the same configuration is activated twice and services restart
- **THEN** no duplicate accounts or integrations are created, existing libraries and history remain, and managed settings converge to their declared values

### Requirement: Repository-managed server and client configuration
Shared services SHALL be managed by importable NixOS modules under `modules/services/tools/`. Supported user application packages and dotfiles SHALL be managed by Home Manager modules under `modules/users/shared/`, imported only by `casper@technative-casper`, `casper@gaming-casper` and `casper@personal-casper`, including their NixOS-integrated equivalents. A web-only client SHALL have its server settings managed through NixOS; it SHALL NOT require invented local dotfiles or Home Manager ownership of server state.

#### Scenario: Client profile recreation
- **WHEN** a selected user profile is rebuilt on a supported client host
- **THEN** its declared applications and supported non-secret dotfiles are restored from this repository without manual copying or configuration

### Requirement: Separate playback experiences
The stack SHALL provide an open-source music application separate from the movie/TV playback application. Existing media data SHALL be retained until equivalent replacement workflows are verified.

#### Scenario: Independent music use
- **WHEN** a user opens the music application
- **THEN** discovery and playback do not require using the movie/TV application

### Requirement: Music discovery and acquisition from one application
The music application SHALL offer discovery outside the owned library and submit selected music to HolyArrs for acquisition. It SHALL show pending, available and failed states, refresh availability automatically after import, and start a requested track when ready without requiring the user to switch to an administration UI. A wait for acquisition before first playback is acceptable; instantaneous availability is not required.

#### Scenario: Discover an unowned album
- **WHEN** a user selects an available but unowned album recommendation and requests playback
- **THEN** the application submits acquisition to HolyArrs, shows progress and begins playback when the requested track is imported and readable

#### Scenario: Acquisition cannot complete
- **WHEN** no usable release is found or acquisition fails
- **THEN** the application shows the failure and permits retry without reporting the track as playable

### Requirement: Music reuses the approved acquisition subscription
Music discovery and playback SHALL use open-source self-hosted applications without requiring an additional application or streaming subscription. Acquisition SHALL reuse the user's approved existing paid Real-Debrid subscription. YouTube or a paid streaming service SHALL NOT be a required playback fallback. A metadata recommendation is not evidence that playable audio is available.

#### Scenario: Existing debrid subscription only
- **WHEN** a user has the configured Real-Debrid credentials but no paid music-streaming or VPN subscription
- **THEN** discovery, acquisition through HolyArrs and Decypharr, and playback work for releases Real-Debrid can fetch without requiring another subscription

### Requirement: Moonfin video discovery and requests
Moonfin SHALL provide discovery outside the owned library, movie and TV acquisition requests, request status and Jellyfin playback in the same client on Linux, Android and Android/Google TV. A repository-managed Moonbase integration SHALL submit requests to HolyArrs without exposing server credentials or requiring a separate request application. Existing Jellyfin identity and access restrictions SHALL apply.

#### Scenario: Request an unowned movie
- **WHEN** an authorized user discovers an unowned movie in Moonfin and requests it
- **THEN** HolyArrs receives the request through Moonbase, Moonfin shows its status, and playback becomes available only after Jellyfin indexes readable imported media

#### Scenario: Request a show
- **WHEN** an authorized user requests a whole show or selected seasons in Moonfin
- **THEN** the HolyArrs request retains that scope and its status remains visible inside Moonfin

#### Scenario: Reject unauthorized acquisition
- **WHEN** an unauthenticated or unauthorized client attempts acquisition
- **THEN** the request is refused without disclosing credentials or creating a HolyArrs request
