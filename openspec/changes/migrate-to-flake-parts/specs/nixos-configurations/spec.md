# NixOS Configurations Specification

## ADDED Requirements

### Requirement: NixOS Configuration Module
NixOS configurations SHALL be defined in a dedicated flake-parts module.

#### Scenario: Module location
- **WHEN** examining the flake structure
- **THEN** NixOS configurations SHALL be defined in parts/nixos.nix
- **AND** the module SHALL export nixosConfigurations output

#### Scenario: Helper function preservation
- **WHEN** defining NixOS configurations
- **THEN** the makeNixosConf helper function SHALL be available
- **AND** the importFromChannelForSystem helper function SHALL be available
- **AND** both functions SHALL maintain their original logic and signatures

### Requirement: Machine Configuration Definitions
All four NixOS machines SHALL be defined as nixosConfigurations outputs.

#### Scenario: Work machine configuration
- **WHEN** accessing nixosConfigurations
- **THEN** technative-casper SHALL be defined
- **AND** it SHALL use the Work profile from profiles/Work
- **AND** it SHALL enable Hyprland desktop environment

#### Scenario: Gaming machine configuration
- **WHEN** accessing nixosConfigurations
- **THEN** gaming-casper SHALL be defined
- **AND** it SHALL use the Gaming profile from profiles/Gaming
- **AND** it SHALL enable Hyprland desktop environment

#### Scenario: Server machine configuration
- **WHEN** accessing nixosConfigurations
- **THEN** server-casper SHALL be defined
- **AND** it SHALL use the Server profile from profiles/Server
- **AND** it SHALL use aarch64-linux system architecture
- **AND** it SHALL NOT enable any desktop environment

#### Scenario: Personal machine configuration
- **WHEN** accessing nixosConfigurations
- **THEN** personal-casper SHALL be defined
- **AND** it SHALL use the Personal profile from profiles/Personal
- **AND** it SHALL enable Hyprland desktop environment

### Requirement: Build System Integration
NixOS configurations SHALL integrate with home-manager and other system modules.

#### Scenario: home-manager integration
- **WHEN** building a NixOS configuration
- **THEN** home-manager.nixosModules.home-manager SHALL be included
- **AND** home-manager.useGlobalPkgs SHALL be enabled

#### Scenario: Hardware module integration
- **WHEN** building technative-casper configuration
- **THEN** nixos-hardware.nixosModules.framework-13-7040-amd SHALL be included

#### Scenario: Package overlays
- **WHEN** building any NixOS configuration
- **THEN** custom overlays from overlays/default.nix SHALL be applied
- **AND** unstable and pkgs2405 package sets SHALL be available
