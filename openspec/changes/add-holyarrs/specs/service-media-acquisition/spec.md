# Spec Delta

## Purpose

Provides a declarative, private media pipeline on kaito with separate movie/TV and music applications, music discovery outside the owned library, and automated acquisition through HolyArrs before playback.

## ADDED Requirements

### Requirement: Delivered as importable NixOS modules
The pipeline SHALL be delivered as NixOS modules under `modules/services/tools/` (`media-storage`, `holyarrs`, `decypharr`, `jackett`), enabled solely by importing them into a host. No other host than kaito SHALL import them.

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

### Requirement: Existing debrid acquisition remains isolated
Movie and show releases acquired through the existing Real-Debrid pipeline SHALL be exposed as symlinks into its mount without local media copies or seeding on kaito. Music acquisition SHALL satisfy the subscription-free music requirement; the existing paid debrid pipeline SHALL NOT be assumed to satisfy it.

#### Scenario: Grab a cached movie
- **WHEN** HolyArrs grabs a release that Real-Debrid has cached
- **THEN** the item appears under `/data/symlinks` as a symlink into `/data/debrid` and no torrent traffic leaves kaito

#### Scenario: Mount unavailable
- **WHEN** the Real-Debrid mount is not available
- **THEN** imports fail visibly in HolyArrs instead of writing media to local disk

### Requirement: Imports land in the library as links
HolyArrs SHALL accept symlinked downloads and preserve links when importing them into the library, named by its own naming scheme (music as `Artist/Album (Year)/NN - Title.ext`). A separately selected subscription-free music downloader MAY produce local files; their storage policy MUST be established before rollout.

#### Scenario: Import a movie
- **WHEN** a grabbed movie finishes in the downloader
- **THEN** HolyArrs places it under `/data/media/movies` as a link that plays the Real-Debrid file

#### Scenario: Import an album
- **WHEN** the owner adds an artist, marks an album to keep up to date, and a matching release is grabbed
- **THEN** the album's tracks appear under `/data/media/music/<Artist>/<Album> (<Year>)/` as links

### Requirement: Search sources include music
HolyArrs SHALL search sources through Jackett's Torznab feeds, including each site's music categories.

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

### Requirement: Subscription-free music workflow
Music discovery, acquisition and playback SHALL use open-source self-hosted applications without requiring paid subscriptions. YouTube or a paid streaming service SHALL NOT be a required playback fallback. A metadata recommendation is not evidence that playable audio is available.

#### Scenario: No streaming subscription
- **WHEN** a user has no paid music or acquisition subscription
- **THEN** discovery, acquisition from a configured subscription-free source and playback still work for available releases
