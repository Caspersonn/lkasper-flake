# Spec Delta

## Purpose

Provides declarative media services on kaito: Moonfin/HolyArrs video acquisition and playback, and Aurral/slskd music discovery through temporary full-song flows with favorite-to-permanent-library retention. Existing applications and libraries remain available during migration.

## ADDED Requirements

### Requirement: Remux video replacement preserves data and excludes local torrenting
Remux SHALL replace the active Jellyfin video service and provide discovery, stream source and quality selection, and movie/show playback in its own client experience. The existing self-hosted AIOStreams and Real-Debrid path SHALL supply configured external streams. Native P2P acquisition SHALL remain disabled, including during first-run provisioning before normal networking. Setup and credential-bearing addon configuration SHALL remain private. Existing Jellyfin state, media, AIOStreams and music services SHALL be preserved for rollback; removing the service SHALL NOT delete its data. This requirement supersedes the earlier Moonfin/Jellyfin client selection, not historical test evidence.

#### Scenario: Safe first installation
- **WHEN** Remux starts with empty state
- **THEN** setup occurs without external network access and public client access remains unavailable until authentication, source configuration and disabled P2P are verified

#### Scenario: Select a playable release
- **WHEN** an authenticated user selects a movie or show with an available provider stream
- **THEN** the client displays source and quality information and plays the selected stream without requiring a separate request UI or falsely reporting unavailable content as playable

#### Scenario: Roll back the replacement
- **WHEN** the previous Jellyfin configuration is restored
- **THEN** its retained state and media remain available, without resetting accounts or deleting the Remux state

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
The services SHALL use consistent absolute paths under `/data` on the host and in participating containers: `/data/debrid` (Real-Debrid mount), `/data/symlinks` (debrid downloader drop folder), existing `/data/media/{movies,tv,music}` libraries, and isolated local Aurral library, temporary flow and slskd staging paths. Files SHALL have the shared `media` permissions required by their readers and writers. New music storage SHALL NOT overwrite or reorganize existing libraries during bootstrap.

#### Scenario: Paths agree everywhere
- **WHEN** an existing debrid-backed symlink under `/data/symlinks` or `/data/media` is resolved on the host, in HolyArrs or in Decypharr
- **THEN** it resolves to the same file under `/data/debrid`

#### Scenario: Group access
- **WHEN** a file is created under `/data/media` by HolyArrs
- **THEN** it belongs to group `media` and is writable by that group

### Requirement: Video acquisition uses the existing debrid service
Movie and show releases SHALL be acquired through HolyArrs and Decypharr using the existing paid Real-Debrid service and exposed as symlinks into its mount, without retained full local video copies or seeding on kaito. No local torrent client or additional VPN service SHALL be introduced for this path. Application state, artwork and bounded operational caches MAY remain local. The separate Aurral/slskd music path SHALL download local audio files and SHALL NOT be represented as Real-Debrid-mediated acquisition.

Decypharr's Hearsay peer discovery and publishing SHALL be explicitly disabled; remote acquisition SHALL NOT implicitly enable an additional peer network on kaito.

#### Scenario: Grab a cached movie
- **WHEN** HolyArrs grabs a release that Real-Debrid has cached
- **THEN** the item appears under `/data/symlinks` as a symlink into `/data/debrid` and no torrent traffic leaves kaito

#### Scenario: Mount unavailable
- **WHEN** the Real-Debrid mount is not available
- **THEN** imports fail visibly in HolyArrs instead of writing media to local disk

#### Scenario: Video acquisition cannot complete
- **WHEN** Real-Debrid cannot fetch a movie or show release
- **THEN** failure is shown without falling back to a local torrent client or the music downloader

### Requirement: Imports land in the library as links
HolyArrs SHALL accept debrid-backed symlinked downloads and preserve links when importing them into its library, named by its own naming scheme. Playback services SHALL read these links through the shared mount without requiring complete retained local copies. Existing debrid-backed music links SHALL remain intact; new Aurral/slskd music follows the separate local-file retention requirements.

#### Scenario: Import a movie
- **WHEN** a grabbed movie finishes in the downloader
- **THEN** HolyArrs places it under `/data/media/movies` as a link that plays the Real-Debrid file

#### Scenario: Preserve existing debrid-backed albums
- **WHEN** Aurral and slskd are introduced alongside the existing services
- **THEN** existing music links and their naming remain unchanged and are not converted into Aurral-owned files

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
Soundspan, Navidrome, AIOStreams and unrelated kaito services SHALL remain available while the selected replacement is introduced. Their state and existing libraries SHALL NOT be removed before replacement acceptance and explicit removal approval. Optional Navidrome integration SHALL preserve its existing libraries, identities, playlists and history.

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

### Requirement: Full-song discovery flows and playback
Aurral SHALL offer scheduled, rotating mixed-artist discovery flows containing music outside the owned library, acquired through slskd as temporary full audio files. A repository-managed initial recipe SHALL work without prior listening history and SHALL enable automatic downloads. The playback application SHALL play readable full tracks consecutively from a prepared flow without switching to an administration UI. It SHALL distinguish waiting, downloading, playable and failed items and allow retry. A wait for acquisition is acceptable; 30-second previews, metadata-only recommendations and claims of guaranteed instant endless streaming SHALL NOT satisfy this requirement.

#### Scenario: Prepare and play outside-library discovery
- **WHEN** a configured discovery flow runs with working Soulseek access
- **THEN** it selects tracks from multiple artists including artists outside the owned library, downloads full audio into temporary flow storage, and offers consecutive full-track playback as files become readable

#### Scenario: Start without listening history
- **WHEN** the initial configured flow runs for a fresh account with no plays recorded
- **THEN** its configured discovery sources or artist seeds can produce candidates without requiring manual recommendation setup

#### Scenario: Acquisition cannot complete
- **WHEN** Soulseek is disconnected, a peer queues a transfer, no matching file exists or validation fails
- **THEN** the application shows waiting or failure and permits retry without reporting an unavailable full track as playable or silently enabling another source

### Requirement: Favorite flow tracks become permanent library items
Aurral's Subsonic endpoint SHALL be configured so that favoriting a downloaded flow track retains it in the permanent library. The user SHALL also be able to keep a track explicitly through Add to library. Retention SHALL survive flow rotation, restarts and repeated favorite actions without duplicate files or acquisitions. Removing a favorite or static playlist entry SHALL NOT implicitly delete retained audio. Artist favorites or follows SHALL NOT automatically download an entire discography.

#### Scenario: Like a discovery track
- **WHEN** a user favorites a downloaded flow track in a supported client connected to Aurral's Subsonic endpoint
- **THEN** the track becomes a permanent library item and remains readable and playable after the flow rotates and services restart

#### Scenario: Rotate while retention is pending
- **WHEN** a flow rotates while a favorite or Add to library action is being processed
- **THEN** cleanup preserves the track until its retained file and library record are safe, and repeated actions do not create duplicate acquisition

#### Scenario: Favorite through a different backend
- **WHEN** a client connects directly to Navidrome instead of Aurral
- **THEN** that connection is not advertised as supporting Aurral's favorite-to-library action unless the behavior is separately implemented and verified

### Requirement: Bounded temporary music storage and durable retention
Temporary flow audio, incomplete downloads and permanent library tracks SHALL have distinct ownership/retention rules. Disk budgets, minimum free space and cleanup SHALL be declared in the repository. Rotation SHALL reclaim expired unkept flow files without deleting permanent tracks, other active references or pre-existing libraries. Backup/recovery SHALL cover Aurral/slskd state, favorites, recipes and credentials and define protection for permanent local audio; temporary flow audio MAY be regenerated. Same-server backups SHALL NOT be described as protection against disk loss.

#### Scenario: Rotation and disk pressure
- **WHEN** a flow is replaced or its temporary storage reaches the declared budget
- **THEN** only eligible unkept temporary files are reclaimed; insufficient safe free space pauses acquisition visibly rather than deleting permanent library audio

#### Scenario: Restore the music workflow
- **WHEN** protected service state and retained music are restored through the declared recovery procedure
- **THEN** accounts, favorites, retained playable tracks and managed flow settings return without manual configuration, while missing temporary flow audio can be downloaded again

### Requirement: Music uses the selected Soulseek source without a paid streaming dependency
Music discovery and playback SHALL use open-source self-hosted Aurral and slskd without requiring an additional application or music-streaming subscription. Acquisition SHALL use direct Soulseek transfers rather than depend on Real-Debrid, Seerr or Lidarr. Other acquisition fallbacks SHALL remain disabled unless separately selected. Soulseek peer exposure and any listening/share policy SHALL be documented and repository-managed; existing libraries SHALL NOT be shared implicitly. slskd administration SHALL remain private and authenticated. No torrent client or anonymity guarantee SHALL be introduced.

#### Scenario: Independent music acquisition
- **WHEN** Aurral has valid slskd/Soulseek access and no paid streaming credentials or Real-Debrid access
- **THEN** matching available music can be downloaded and played through the selected flow workflow without a paid streaming fallback

#### Scenario: Explicit network and sharing policy
- **WHEN** the music services are activated
- **THEN** management access is authenticated, peer-listening and share paths follow the declared policy, the direct public-IP exposure is documented, and no existing library becomes an upload share implicitly

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
