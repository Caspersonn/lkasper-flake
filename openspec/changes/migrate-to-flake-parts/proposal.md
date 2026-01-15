# Change: Migrate NixOS configurations to flake-parts

## Why
The current flake.nix is a monolithic 273-line file containing all configuration logic for multiple NixOS systems, home-manager configurations, and helper functions. As the number of machines and configurations grows, this approach becomes harder to maintain, navigate, and extend. flake-parts provides a module system for organizing flakes into smaller, composable pieces while maintaining the same functionality.

## What Changes
- Adopt flake-parts as the flake organization framework
- Restructure flake.nix to use the flake-parts module system
- Extract NixOS configuration logic into modular flake-parts modules
- Maintain backward compatibility - all existing NixOS configurations (technative-casper, gaming-casper, server-casper, personal-casper) must continue to work
- Keep home-manager configurations unchanged for now (out of scope for this migration)
- Preserve all existing helper functions (makeHomeConf, makeNixosConf, importFromChannelForSystem)

## Impact
- **Affected specs**: flake-structure, nixos-configurations
- **Affected code**:
  - flake.nix (complete restructure)
  - New files: flake-parts modules for NixOS configurations, systems, and overlays
- **Breaking changes**: None - all outputs remain identical
- **Benefits**:
  - Better code organization and maintainability
  - Easier to add new machines or profiles
  - Clearer separation of concerns
  - Foundation for future modularization (home-manager, overlays, etc.)
