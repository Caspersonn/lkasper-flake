# Design: Migrate to flake-parts

## Context
The current flake.nix contains all configuration in a single file with nested let-bindings and helper functions. While functional, this approach doesn't scale well. flake-parts is a module system for Nix flakes that enables splitting large flakes into composable modules, similar to how NixOS modules work.

**Current structure:**
- Single flake.nix with ~273 lines
- Helper functions: makeHomeConf, makeNixosConf, importFromChannelForSystem
- 4 NixOS configurations
- 5 home-manager configurations
- Multiple flake inputs (~20+)

**Constraints:**
- Must maintain all existing functionality
- Home-manager configurations remain unchanged (out of scope)
- No breaking changes to outputs
- Personal project - prioritize simplicity over premature abstraction

## Goals / Non-Goals

**Goals:**
- Adopt flake-parts for NixOS configuration organization
- Split monolithic flake.nix into logical modules
- Maintain all existing nixosConfigurations outputs
- Create clear, understandable module structure
- Provide foundation for future modularization

**Non-Goals:**
- Migrating home-manager configurations (separate future change)
- Changing module paths or profiles structure
- Modifying any NixOS module implementations
- Performance optimization
- Adding new features beyond flake-parts adoption

## Decisions

### Decision 1: Module Organization Structure
**What:** Organize flake-parts modules in a `parts/` directory at repository root

**Structure:**
```
parts/
├── systems.nix          # System configurations (x86_64-linux, aarch64-linux)
├── nixos.nix            # NixOS configurations (all 4 machines)
├── home-manager.nix     # Home-manager configurations (unchanged, just moved)
├── overlays.nix         # Overlay configuration
└── formatter.nix        # Formatter configuration
```

**Why:**
- Clear separation by output type
- Easy to locate specific configuration types
- Standard naming convention used in flake-parts community
- Shallow structure keeps navigation simple

**Alternatives considered:**
- `flake-parts/` directory - Too verbose, `parts/` is conventional
- Flat in root - Would clutter repository root
- Nested by feature - Over-engineering for current scale

### Decision 2: perSystem vs Non-perSystem Split
**What:** Use perSystem for packages, overlays, and formatter; use top-level for nixosConfigurations and homeConfigurations

**Why:**
- nixosConfigurations and homeConfigurations are already system-specific in their definitions
- perSystem would add unnecessary complexity for these outputs
- Overlays and formatters benefit from perSystem's automatic system iteration

### Decision 3: Preserve Helper Functions
**What:** Keep makeHomeConf, makeNixosConf, and importFromChannelForSystem helper functions

**Where:** Define in the specific module files where they're used (nixos.nix, home-manager.nix)

**Why:**
- These functions encapsulate useful logic for DRY configuration
- No benefit to changing them during migration
- Minimizes risk of breaking changes
- Can be refactored later if needed

### Decision 4: Migration Strategy
**What:** Single-step migration with thorough testing

**Steps:**
1. Add flake-parts to inputs
2. Create all parts/ modules with existing logic
3. Update flake.nix to import flake-parts and modules
4. Test each configuration builds successfully
5. Verify no output changes with nix flake show comparison

**Why:**
- Small scope makes single-step feasible
- Easier to review and verify
- Reduces potential for partial state issues

**Alternative considered:**
- Incremental migration (one config at a time) - Adds complexity with mixed state

## Risks / Trade-offs

### Risk: Breaking existing configurations
**Mitigation:**
- Keep all helper functions and logic identical
- Test all 4 NixOS configs build before committing
- Use `nix flake show` to verify outputs match

### Risk: Increased complexity from new dependency
**Trade-off:**
- Adds flake-parts as dependency
- However, reduces complexity in flake.nix organization
- Net benefit: easier to understand and maintain

### Risk: Learning curve for flake-parts
**Mitigation:**
- Keep initial migration simple
- Document module structure in comments
- Link to flake-parts documentation in project.md

## Migration Plan

### Pre-migration
1. Ensure current flake builds successfully
2. Run `nix flake show` and save output for comparison
3. Create backup branch

### Migration steps
1. Add flake-parts to flake inputs
2. Create parts/ directory and module files
3. Port existing logic to appropriate modules
4. Update flake.nix to use flake-parts
5. Build test each nixosConfiguration
6. Compare `nix flake show` output

### Validation
- `nix flake check` passes
- All 4 NixOS configurations build: `nix build .#nixosConfigurations.{technative-casper,gaming-casper,server-casper,personal-casper}.config.system.build.toplevel`
- Home-manager configurations unchanged and functional
- `nix flake show` output identical (except structure)

### Rollback
If issues occur:
- Git revert to previous commit
- All changes in single commit for easy revert
- No state changes - purely structural refactor

## Open Questions

None - scope is clear and well-defined for initial migration. Future enhancements (home-manager modularization, overlay organization) can be addressed in separate changes.
