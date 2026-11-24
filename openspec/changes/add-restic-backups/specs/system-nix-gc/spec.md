# Spec Delta

## Purpose

Keeps disk usage bounded on hosts that import it. It runs daily Nix garbage collection, automatic store optimisation and pruning of dangling container images, which frees kaito's disk for backups. This is a NixOS module in `modules/nix/` that kaito imports in this change. Other hosts can import it later.

## ADDED Requirements

### Requirement: Enabled by import
The cleanup SHALL be a NixOS module in `modules/nix/` that takes effect when a host imports it. It SHALL have no enable option. kaito SHALL import it. No other host's behaviour SHALL change in this change.

#### Scenario: kaito imports cleanup
- **WHEN** kaito's configuration is built
- **THEN** it contains the scheduled garbage collection, store optimisation and image pruning

#### Scenario: Other hosts unchanged
- **WHEN** gaming-casper, personal-casper, technative-casper or sakura are built
- **THEN** they contain no garbage collection schedule from this module

### Requirement: Daily garbage collection that keeps recent rollbacks
The host SHALL run Nix garbage collection daily, and the run SHALL be persistent so it catches up after downtime. Each run SHALL delete profile generations older than 7 days and then the unreferenced store paths. The current generation and all generations from the last 7 days SHALL remain available for rollback.

#### Scenario: Old generations removed
- **WHEN** the daily garbage collection runs on kaito
- **THEN** the system profile contains only generations from the last 7 days plus the current generation
- **AND** the store paths that only old generations used are deleted

#### Scenario: Rollback remains possible
- **WHEN** a deployment from 3 days ago must be restored after garbage collection ran
- **THEN** that generation is still available to switch or boot into

### Requirement: Store optimisation
The host SHALL run Nix store optimisation automatically on a schedule. Optimisation hard-links identical files in the store.

#### Scenario: Optimisation scheduled
- **WHEN** kaito's systemd timers are listed
- **THEN** a Nix store optimisation timer is active

### Requirement: Conservative container image pruning
If Docker is enabled on the host, the host SHALL prune daily the dangling (untagged) Docker images that are older than 7 days. The pruning SHALL NOT remove any of the following:
- tagged images
- containers
- volumes
- networks

If Docker is not enabled, the module SHALL add no container pruning.

#### Scenario: Application data and networks survive pruning
- **WHEN** the daily image prune runs on kaito
- **THEN** the Docker volumes, the `solidtime-net` network and the tagged images of stopped containers still exist

#### Scenario: Host without Docker
- **WHEN** a host without Docker imports the cleanup module
- **THEN** its configuration builds
- **AND** it contains no container pruning service
