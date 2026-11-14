# Spec Delta

## Purpose

Provides a private, self-hosted pipeline on kaito that searches sources, acquires movies, shows and music through Real-Debrid and organises them into a shared on-disk library for a media server to serve.

## ADDED Requirements

### Requirement: Delivered as importable NixOS modules
The pipeline SHALL be delivered as NixOS modules under `modules/services/tools/` (`media-storage`, `holyarrs`, `decypharr`, `jackett`), enabled solely by importing them into a host. No other host than kaito SHALL import them.

#### Scenario: Only kaito changes
- **WHEN** every `nixosConfigurations` output is evaluated after the change
- **THEN** only kaito's system closure contains HolyArrs, Decypharr and Jackett, and the other hosts' closures are unchanged by this change

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

### Requirement: Downloads go through Real-Debrid without local copies
Grabbed releases SHALL be acquired through the user's Real-Debrid account. The downloader SHALL expose finished items as symlinks into the Real-Debrid mount; kaito SHALL NOT seed torrents or store the media files themselves.

#### Scenario: Grab a cached movie
- **WHEN** HolyArrs grabs a release that Real-Debrid has cached
- **THEN** the item appears under `/data/symlinks` as a symlink into `/data/debrid` and no torrent traffic leaves kaito

#### Scenario: Mount unavailable
- **WHEN** the Real-Debrid mount is not available
- **THEN** imports fail visibly in HolyArrs instead of writing media to local disk

### Requirement: Imports land in the library as links
HolyArrs SHALL accept symlinked downloads and place imported items in the library as links, named by its own naming scheme (music as `Artist/Album (Year)/NN - Title.ext`).

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

### Requirement: No secrets in the repository
Real-Debrid credentials, HolyArrs and Decypharr login passwords, API keys and HolyArrs' master key SHALL NOT be stored in the repository, in plain text or encrypted. They SHALL be set through the services' own interfaces and kept in their state directories.

#### Scenario: Repository scan
- **WHEN** the repository is searched for the Real-Debrid token, the Jackett API key or HolyArrs credentials
- **THEN** none are found

### Requirement: Existing services are unaffected
Navidrome, AIOStreams and all other kaito services SHALL keep running unchanged while this pipeline is introduced.

#### Scenario: After deployment
- **WHEN** the change is activated on kaito
- **THEN** Navidrome and AIOStreams still serve their existing virtual hosts and libraries
