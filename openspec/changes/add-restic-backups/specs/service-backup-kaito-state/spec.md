# Spec Delta

## Purpose

Protects kaito's irreplaceable service state with a daily, client-side encrypted, offsite restic backup of `/var/lib` and consistent database dumps to S3. This covers Vaultwarden, Home Assistant with Zigbee/Matter/Thread pairing, Atuin (including the synced AI threads), Solidtime and others. This is a NixOS module in `modules/services/backup/` that only kaito imports.

## ADDED Requirements

### Requirement: Daily offsite state backup
kaito SHALL back up `/var/lib` and its database dump directory once a day to its own prefix in the S3 bucket. Snapshots SHALL be tagged `state`. The job SHALL be persistent, so a missed run happens after the next boot. kaito SHALL NOT keep a copy of its state backup on its own disk. The job SHALL use kaito's own repository password and S3 key. Only kaito and the admin user MAY decrypt them.

#### Scenario: Nightly run
- **WHEN** the daily state job completes
- **THEN** a new snapshot tagged `state` exists in kaito's S3 repository

#### Scenario: kaito was down at the scheduled time
- **WHEN** kaito boots after missing the scheduled run
- **THEN** the state backup runs shortly after boot

### Requirement: Consistent database dumps
Databases SHALL be backed up from dumps that are consistent at a point in time, and not from live database files:
- every PostgreSQL database managed by NixOS on kaito, including Atuin's
- Vaultwarden's SQLite database, through an SQLite-safe backup
- Solidtime's dockerised PostgreSQL, dumped from inside its container

The dumps SHALL be taken before the snapshot on the same day. A dump step SHALL only run when its service is configured on kaito. If the dump of a configured service fails, the state job SHALL be marked failed.

#### Scenario: Restoring the Vaultwarden dump
- **WHEN** the Vaultwarden backup from the latest snapshot is restored into an empty data directory
- **THEN** Vaultwarden starts and the vault contents are present

#### Scenario: Restoring a PostgreSQL dump
- **WHEN** the Atuin database dump from the latest snapshot is loaded into an empty PostgreSQL
- **THEN** the database contains the synced history and threads up to the time of the dump

#### Scenario: Service removed from kaito
- **WHEN** Solidtime is no longer imported on kaito
- **THEN** kaito still builds
- **AND** the state job no longer attempts a Solidtime dump

#### Scenario: Dump fails
- **WHEN** Solidtime is configured but its database container is not running when the state job starts
- **THEN** the state job is marked failed in systemd

### Requirement: State that must be included
The state backup SHALL include at least the following, when present:
- `/var/lib/nixos` (user and group ID maps)
- Home Assistant configuration and `.storage`
- Zigbee2MQTT data, including the network key
- the Matter server fabric data under `/var/lib/private`
- Thread border router data
- `/var/lib/minecraft`
- `/var/lib/holyarrs`
- Solidtime's bind-mounted directories and its application storage Docker volume

#### Scenario: Pairing data survives
- **WHEN** the latest state snapshot is listed
- **THEN** it contains Zigbee2MQTT's configuration with the network key, the Matter server data and Home Assistant's `.storage`

### Requirement: Reproducible, bulky and live data excluded
The state backup SHALL exclude the following:
- Docker's image and container storage (except the application storage volumes that are explicitly included)
- the live PostgreSQL data directory and Vaultwarden's live SQLite database files, which are covered by dumps (Vaultwarden's other files, such as attachments and keys, stay included)
- Home Assistant's recorder database
- Ollama models
- Redis data
- systemd coredumps
- machine and container images
- any directory with a valid `CACHEDIR.TAG`

The backup SHALL stay on kaito's root filesystem and SHALL NOT include any restic repository data from the kaito REST server.

#### Scenario: No client repositories in state snapshots
- **WHEN** the state snapshot is listed
- **THEN** it contains no files from the REST server's repository directory

#### Scenario: Docker images not uploaded
- **WHEN** the state snapshot is listed
- **THEN** it contains no Docker image layers or container filesystems

### Requirement: Retention and checks by the repository capability
kaito's state repository SHALL be included in the server-side S3 retention and integrity checks defined by the backup repository capability. The state job itself SHALL NOT run `forget` or `prune`.

#### Scenario: State repository pruned weekly
- **WHEN** the weekly S3 retention runs on kaito
- **THEN** kaito's state snapshots are thinned to the configured S3 policy
