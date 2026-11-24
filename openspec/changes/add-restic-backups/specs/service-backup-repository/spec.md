# Spec Delta

## Purpose

Provides the restic REST repository on kaito that receives the workstation backups. It also runs all retention, pruning and integrity checks for the kaito and S3 repositories on kaito, so client hosts never need delete rights. This is a NixOS module in `modules/services/backup/` that kaito imports. A flake-level registry in the same directory holds the shared settings.

## ADDED Requirements

### Requirement: Central backup registry
A flake-level backup registry SHALL hold the shared backup settings:
- the repository server host and port
- the S3 bucket and region
- the retention policies
- the set of client hosts, each with optional host-specific additions

Client and server modules SHALL read these values from the registry instead of repeating them. Adding a client to the registry SHALL be enough for kaito to generate that client's maintenance jobs. The htpasswd entry and the secrets are created separately by the user.

#### Scenario: New client registered
- **WHEN** a new host is added to the registry and kaito is rebuilt
- **THEN** kaito's configuration contains retention and check jobs for that host's kaito and S3 repositories
- **AND** kaito's own module files did not have to be edited

### Requirement: Mesh-only authenticated REST repository
kaito SHALL run a restic REST server on a dedicated TCP port that no other kaito service uses. The port SHALL be reachable only through kaito's Nebula interface, and not from the LAN or the public internet. Every request SHALL be authenticated with a per-host username and password. The server SHALL read these credentials from an agenix secret that only kaito and the admin user can decrypt. Plain HTTP SHALL only be used inside the encrypted Nebula tunnel.

#### Scenario: Access from a mesh client
- **WHEN** a registered client connects to kaito's mesh address on the repository port with valid credentials
- **THEN** the server serves that client's repository

#### Scenario: Access from outside the mesh
- **WHEN** a device connects to kaito's LAN address or public endpoint on the repository port
- **THEN** the connection is refused

#### Scenario: Missing or wrong credentials
- **WHEN** a request without valid credentials reaches the server over the mesh
- **THEN** the server rejects it as unauthorised

### Requirement: Private repository per host
Each authenticated user SHALL be able to access only the repository path that matches its own user name, which is the host name.

#### Scenario: Host reads another host's repository
- **WHEN** technative-casper authenticates and requests sakura's repository path
- **THEN** the server refuses the request

### Requirement: Append-only for clients
Clients SHALL NOT be able to delete or overwrite stored data through the REST server. The only exception is restic lock files.

#### Scenario: Client forgets snapshots
- **WHEN** a client runs `restic forget --prune` against its kaito repository
- **THEN** the server refuses the deletions and all snapshots remain

### Requirement: Repository storage location
Repository data SHALL be stored on kaito's local filesystem, outside `/var/lib`, and owned by a dedicated unprivileged service user. That way the kaito state backup does not upload client repositories a second time.

#### Scenario: Data location
- **WHEN** a client completes a backup to kaito
- **THEN** the new data is stored below the configured repository directory outside `/var/lib`, owned by the service user

### Requirement: Server-side retention for kaito repositories
kaito SHALL apply retention to every registered client's kaito repository at least weekly, by accessing the repository directly on disk rather than through the append-only server. The default policy SHALL keep 24 hourly, 7 daily and 4 weekly snapshots, grouped by host and path. Unreferenced data SHALL be pruned afterwards. The newest snapshot of every series SHALL always be kept.

#### Scenario: Weekly prune
- **WHEN** kaito's retention job runs for host X
- **THEN** snapshots outside the policy are removed
- **AND** unreferenced data is pruned
- **AND** host X's newest snapshot still exists

### Requirement: Server-side retention for S3 repositories
kaito SHALL apply retention at least weekly to every registered client's S3 repository and to kaito's own state repository. It SHALL use a dedicated S3 key that is allowed to delete objects. Only kaito and the admin user MAY decrypt that key. The default policy SHALL keep 7 daily, 4 weekly and 12 monthly snapshots, then prune unreferenced data. To do this, kaito SHALL hold the repository password of every registered host.

#### Scenario: S3 prune with the prune key
- **WHEN** kaito's S3 retention job runs for host X
- **THEN** snapshots outside the policy are removed from host X's prefix using the prune key
- **AND** host X's own S3 key was not needed

#### Scenario: Prune key is not on clients
- **WHEN** a client host's configuration is built
- **THEN** the prune key secret is not deployed to that host

### Requirement: Integrity checks
kaito SHALL check every registered repository at least weekly:
- kaito-local repositories SHALL be checked including a random subset of at least 10% of the pack data
- S3 repositories SHALL be checked for structural consistency without reading all pack data, to avoid egress costs

A failed check SHALL be visible as a failed systemd unit on kaito.

#### Scenario: Corrupted local pack
- **WHEN** a pack file in a kaito-local repository is corrupted and is in the sampled subset
- **THEN** the check job fails and the failure appears in `systemctl --failed` on kaito

### Requirement: Safe concurrency with clients
Retention and check jobs MUST rely on restic repository locking, so a client backup running at the same time cannot cause corruption. If a maintenance job cannot get its lock, it SHALL fail without modifying the repository, and the next scheduled run SHALL retry.

#### Scenario: Client backs up during prune
- **WHEN** a client starts a backup while kaito prunes that client's repository
- **THEN** one of the two waits or fails cleanly
- **AND** the repository passes `restic check` afterwards
