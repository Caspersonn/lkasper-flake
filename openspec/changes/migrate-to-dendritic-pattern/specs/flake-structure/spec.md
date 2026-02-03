## MODIFIED Requirements

### Requirement: Flake Structure Organization

The NixOS flake SHALL be organized using the Dendritic Pattern with flake-parts framework, where all NixOS configuration is composed from reusable features rather than host-centric modules.

**Previous approach**: Host-centric with profiles importing modules  
**New approach**: Feature-centric with bottom-up composition  
**Scope**: NixOS configuration only (Home-Manager remains in `home/` directory)

#### Scenario: Feature defines NixOS configuration
- **GIVEN** a feature needs to define NixOS system configuration
- **WHEN** the feature is defined using flake.modules
- **THEN** it SHALL define `flake.modules.nixos.<feature>`
- **AND** the aspect SHALL be automatically available for use in host configurations

#### Scenario: Feature optionally includes home-manager configuration
- **GIVEN** a feature needs both system and home-manager configuration (Multi-Context Aspect)
- **WHEN** the feature is defined
- **THEN** it SHALL define both `flake.modules.nixos.<feature>` and `flake.modules.homeManager.<feature>`
- **AND** the NixOS aspect SHALL import the homeManager aspect via `home-manager.sharedModules`
- **AND** home-manager configuration remains in `home/` directory as existing practice

#### Scenario: Host is composed from features
- **GIVEN** a host configuration needs to be created
- **WHEN** the host feature is defined in `modules/hosts/<hostname> [N]/`
- **THEN** it SHALL import other features using the Inheritance Aspect pattern
- **AND** the host SHALL be minimal, primarily composed of feature imports and host-specific overrides
- **AND** host SHALL have `configuration.nix` and `flake-parts.nix` files

#### Scenario: Adding new feature to existing host
- **GIVEN** an existing host configuration
- **WHEN** a new feature needs to be added to the host
- **THEN** it SHALL require only adding the feature to the host's imports list
- **AND** the feature SHALL be self-contained with all necessary configuration

## ADDED Requirements

### Requirement: Dendritic Aspect Patterns

Features SHALL be implemented using one or more of the 8 Dendritic Aspect patterns based on their composition needs.

#### Scenario: Simple feature (Simple Aspect)
- **GIVEN** a basic feature that works in one context (e.g., NixOS-only service)
- **WHEN** the feature is implemented
- **THEN** it SHALL use the Simple Aspect pattern
- **AND** define only `flake.modules.<class>.<feature-name>`

#### Scenario: Feature with system and home-manager config (Multi-Context Aspect)
- **GIVEN** a feature that needs both system and home-manager configuration (e.g., desktop environment)
- **WHEN** the feature is implemented
- **THEN** it SHALL use the Multi-Context Aspect pattern
- **AND** define a main `flake.modules.nixos.<feature>` module
- **AND** define an auxiliary `flake.modules.homeManager.<feature>` module
- **AND** the main module SHALL import the auxiliary module using `home-manager.sharedModules`

#### Scenario: Feature composes other features (Inheritance Aspect)
- **GIVEN** a feature that builds upon existing features (e.g., system types, hosts)
- **WHEN** the feature is implemented
- **THEN** it SHALL use the Inheritance Aspect pattern
- **AND** import parent features using `imports = with inputs.self.modules.<class>; [ parent-feature ];`

#### Scenario: Platform-specific configuration (Conditional Aspect)
- **GIVEN** a feature that behaves differently on Linux vs Darwin
- **WHEN** the feature is implemented
- **THEN** it SHALL use the Conditional Aspect pattern
- **AND** use `lib.mkIf` with `pkgs.stdenv.isLinux` or `pkgs.stdenv.isDarwin`
- **AND** merge conditional parts using `lib.mkMerge`

#### Scenario: Feature collects contributions from others (Collector Aspect)
- **GIVEN** a feature needs configuration from multiple other features (e.g., syncthing device IDs)
- **WHEN** the feature is implemented
- **THEN** it SHALL use the Collector Aspect pattern
- **AND** define the main feature with base configuration
- **AND** other features SHALL contribute to the same aspect path to add their data

#### Scenario: Shared constants across features (Constants Aspect)
- **GIVEN** constants need to be shared across multiple features
- **WHEN** the constants are defined
- **THEN** they SHALL use the Constants Aspect pattern
- **AND** define options using `flake.modules.generic.<constants-aspect>`
- **AND** be importable in any module class (NixOS, Darwin, Home-Manager)

#### Scenario: Reusable attribute components (DRY Aspect)
- **GIVEN** attribute sets are repeated in multiple locations (e.g., network interface configs)
- **WHEN** the reusable component is created
- **THEN** it SHALL use the DRY Aspect pattern
- **AND** define a custom module class for the attribute type
- **AND** be usable in attribute assignments with `lib.mkMerge`

#### Scenario: Parameterized feature generation (Factory Aspect)
- **GIVEN** a pattern is repeated with different parameters (e.g., users, mounts)
- **WHEN** the factory is implemented
- **THEN** it SHALL use the Factory Aspect pattern
- **AND** define a function in `flake.factory.<factory-name>`
- **AND** return either named aspect modules or anonymous modules
- **AND** accept parameters as function arguments

### Requirement: Feature Organization

Features SHALL be organized in a hierarchical directory structure under `modules/` following dendritic conventions with naming suffixes that indicate module class support.

#### Scenario: Feature directory placement and naming
- **GIVEN** a new feature is being created
- **WHEN** determining file location and name
- **THEN** it SHALL be placed in the appropriate category subdirectory:
  - `modules/nix/` for Nix infrastructure and tooling
  - `modules/system/` for system-level features (settings, system types)
  - `modules/programs/` for program features
  - `modules/services/` for system services
  - `modules/factory/` for factory aspects
  - `modules/hosts/` for host definitions
  - `modules/users/` for user-specific customizations
- **AND** directory name SHALL include suffix indicating module class support:
  - `[N]` for NixOS only
  - `[D]` for Darwin only
  - `[ND]` for NixOS + Darwin
  - `[nd]` for NixOS + Darwin + Home-Manager
  - Custom suffixes like `[networkInterfaces]` for DRY aspects
- **AND** the aspect name SHALL match the directory name (without suffix) for discoverability

#### Scenario: General features vs user customizations
- **GIVEN** a feature is being designed
- **WHEN** deciding between general feature or user customization
- **THEN** general features SHALL be defined in `modules/<category>/`
- **AND** general features SHALL be reusable by any user or host
- **AND** user-specific customizations SHALL be defined in `modules/users/<username>/`
- **AND** user modules SHALL import general features and add customizations

#### Scenario: Complex feature with multiple files
- **GIVEN** a feature that is too large for a single file
- **WHEN** organizing the feature
- **THEN** it SHALL be placed in a directory named after the feature with appropriate suffix
- **AND** split into logical sub-files within the directory
- **AND** all sub-files SHALL be automatically merged by flake-parts
- **AND** related files (e.g., impermanence) MAY be colocated in the feature directory

### Requirement: Automatic Feature Discovery

All features SHALL be automatically discovered and imported from the `modules/` directory without manual flake.nix maintenance.

#### Scenario: New feature is automatically available
- **GIVEN** a new feature file is created in `modules/` directory
- **WHEN** the flake is evaluated
- **THEN** the feature SHALL be automatically imported by import-tree
- **AND** be available as `inputs.self.modules.<class>.<feature-name>`
- **AND** no manual import statement SHALL be required in flake.nix

#### Scenario: Disabling feature during development
- **GIVEN** a feature is being developed or debugged
- **WHEN** the feature needs to be temporarily disabled
- **THEN** it SHALL be possible by prefixing filename/directory with underscore `_`
- **AND** import-tree SHALL automatically skip it

#### Scenario: Flake.nix is automatically generated
- **GIVEN** a feature defines new flake inputs using flake-file
- **WHEN** flake inputs are added to a feature
- **THEN** flake.nix SHALL be regenerated with `nix run .#write-flake`
- **AND** no manual flake.nix editing SHALL be required
- **AND** flake-file inputs SHALL be defined in feature using `flake-file.inputs`

### Requirement: Helper Library and Factory Functions

The configuration SHALL provide helper functions for common patterns and factory functions for parameterized feature generation.

#### Scenario: Creating NixOS configuration from host feature
- **GIVEN** a host feature is defined in `modules/hosts/<hostname> [N]/`
- **WHEN** creating the nixosConfiguration in `flake-parts.nix`
- **THEN** it SHALL use `inputs.self.lib.mkNixos system hostname`
- **AND** automatically apply the host feature module and set hostPlatform

#### Scenario: Factory library option is available
- **GIVEN** factory aspects need to be defined
- **WHEN** the factory infrastructure is set up
- **THEN** `flake.factory` option SHALL be defined in `modules/nix/flake-parts/factory.nix`
- **AND** factory functions SHALL be accessible as `inputs.self.factory.<factory-name>`

#### Scenario: Factory function generates feature modules
- **GIVEN** a factory function is defined (e.g., user, mount)
- **WHEN** the factory is invoked with parameters
- **THEN** it SHALL return an attribute set with module aspects
- **AND** aspects MAY be for nixos, darwin, and/or homeManager classes
- **AND** aspects SHALL be usable directly in imports or merged with lib.mkMerge

### Requirement: Secrets Integration

Features that require secrets SHALL integrate with agenix directly within the feature definition.

#### Scenario: Feature uses encrypted secret
- **GIVEN** a feature requires an encrypted secret
- **WHEN** the feature is implemented
- **THEN** it SHALL define `age.secrets.<secret-name>.file = ../../secrets/<secret>.age` within the feature
- **AND** reference the secret path using `config.age.secrets.<secret-name>.path`
- **AND** the secret SHALL be automatically decrypted when the feature is used

### Requirement: Hardware Configuration Integration

Host features SHALL integrate hardware-specific configuration while keeping it separate from the dendritic pattern.

#### Scenario: Host includes hardware configuration
- **GIVEN** a host feature is being defined
- **WHEN** hardware-specific configuration is needed
- **THEN** the host feature SHALL import `./hardware-configuration.nix` directly
- **AND** keep hardware-configuration.nix in the hosts directory alongside the host feature
- **AND** NOT attempt to make hardware configuration reusable across hosts

## REMOVED Requirements

None - this is an architectural enhancement that extends existing requirements rather than removing them.

## RENAMED Requirements

None - requirement names remain consistent with existing spec.
