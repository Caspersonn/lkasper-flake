# Flake Structure Specification

## ADDED Requirements

### Requirement: flake-parts Module System
The flake SHALL use flake-parts as the organization framework for defining outputs and configuration.

#### Scenario: flake-parts as dependency
- **WHEN** the flake is evaluated
- **THEN** flake-parts SHALL be declared as a flake input
- **AND** the flake.nix SHALL import and use flake-parts.lib.mkFlake

#### Scenario: Module-based organization
- **WHEN** defining flake outputs
- **THEN** outputs SHALL be organized into separate module files under parts/
- **AND** each module SHALL be imported into the main flake-parts configuration

### Requirement: Module Organization
The flake SHALL organize configuration modules in a parts/ directory with clear separation of concerns.

#### Scenario: Directory structure
- **WHEN** examining the repository structure
- **THEN** a parts/ directory SHALL exist at the repository root
- **AND** the directory SHALL contain separate modules for different output types

#### Scenario: Module file naming
- **WHEN** creating module files
- **THEN** modules SHALL use descriptive names matching their purpose
- **AND** names SHALL follow the pattern: systems.nix, nixos.nix, home-manager.nix, overlays.nix, formatter.nix

### Requirement: Systems Configuration
The flake SHALL define supported systems using flake-parts systems configuration.

#### Scenario: Supported architectures
- **WHEN** defining systems
- **THEN** x86_64-linux SHALL be configured as a supported system
- **AND** aarch64-linux SHALL be configured as a supported system
- **AND** systems SHALL be defined in parts/systems.nix

### Requirement: Backward Compatibility
The flake SHALL maintain all existing outputs and functionality after migration to flake-parts.

#### Scenario: Existing outputs preserved
- **WHEN** running nix flake show after migration
- **THEN** all nixosConfigurations outputs SHALL remain accessible
- **AND** all homeConfigurations outputs SHALL remain accessible
- **AND** the formatter output SHALL remain accessible

#### Scenario: Configuration builds unchanged
- **WHEN** building any existing configuration
- **THEN** the build SHALL succeed without errors
- **AND** the output SHALL be functionally identical to pre-migration builds
