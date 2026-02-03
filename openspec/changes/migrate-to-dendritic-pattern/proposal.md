# Change: Migrate to Dendritic Flake Pattern

**Status**: ✅ **COMPLETE** (awaiting user testing and cleanup)  
**Completion Date**: 2026-02-03

## Summary

Successfully migrated lkasper-flake to the Dendritic Pattern. All 4 NixOS hosts now compose from 68 reusable feature modules with automatic discovery. System configuration extracted into reusable modules following mipnix pattern.

See [STATUS.md](./STATUS.md) for detailed completion report.

## Why

The current NixOS flake configuration uses flake-parts for basic structuring (systems, formatter, overlays, nixos/home-manager configurations) but follows a traditional top-down approach where hosts are configured by assigning services, applications, and user settings directly to them. This approach leads to:

- Code duplication across similar hosts and profiles
- Difficulty in reusing configuration components across different NixOS contexts
- Complex dependency management between modules
- Limited composability when adding new hosts or features
- Challenging maintenance as the number of hosts and features grows
- Home-Manager configurations tightly coupled to NixOS system configuration
- Helper functions (makeNixosConf, makeHomeConf) handle desktop environment flags but lack feature composability

**Current flake-parts usage**: Basic `parts/*.nix` modules define systems, formatter, overlays, and configuration builders, but don't leverage `flake.modules` for feature composition.

The Dendritic Pattern represents a fundamental paradigm shift - from "hosts have features" to "features are imported by hosts" (bottom-up vs top-down). Features are **simple NixOS modules** that are composed through `imports`, not enabled through options. This migration will provide:

- **Superior code reusability**: Features are direct NixOS configuration that can be imported anywhere
- **Simplified troubleshooting**: All feature-related code is in one module file  
- **Enhanced maintainability**: Adding/removing features is just adding/removing from imports list
- **Better modularity**: Features are self-contained modules with no wrapper options
- **Simpler composition**: `imports = with inputs.self.modules.nixos; [feature1 feature2 ...]`
- **Cross-platform foundation**: Architecture supports future Darwin migration (though not included in this change)

## What Changes

- **BREAKING** Restructure entire flake layout from host-centric to feature-centric architecture
- **Extend existing flake-parts usage** from basic structuring to full dendritic pattern with `flake.modules`
- Convert existing NixOS modules to dendritic features:
  - **Simple modules**: Services and packages as direct NixOS configuration (no `mkEnableOption`)
  - **Composition through imports**: Features enabled by importing, not by setting options
  - **Host modules**: Hosts compose features via `imports = with inputs.self.modules.nixos; [...]`
- Feature structure pattern:
  ```nix
  # modules/services/tailscale.nix (flat file, no subdirectory)
  {
    flake.modules.nixos.tailscale = {
      services.tailscale = {
        enable = true;
        openFirewall = true;
      };
    };
  }
  
  # modules/hosts/gaming-casper/configuration.nix
  { inputs, ... }:
  {
    flake.modules.nixos.gaming-casper = {
      imports = with inputs.self.modules.nixos; [
        tailscale  # Feature enabled by importing
        syncthing
        hyprland
      ];
    };
  }
  ```
- Reorganize `modules/` directory following dendritic structure with **flat file layout**:
  - `modules/nix/` - Nix tooling and flake-parts infrastructure
  - `modules/system/` - System-level configuration (locale, boot, networking, audio, graphics, etc.)
  - `modules/programs/` - Program features organized by category (following mipnix pattern)
    - `programs/desktop/` - Desktop environments (hyprland.nix, gnome.nix, kde.nix, cosmic.nix)
    - `programs/cli/` - CLI tools and utilities
    - `programs/dev/` - Development tools (git.nix, languages.nix, lsp.nix)
    - `programs/gaming/` - Gaming programs
    - `programs/gui/` - GUI applications
    - `programs/work/` - Work-specific tools
    - `programs/server/` - Server tools
    - `programs/system/` - System utilities
    - All as **flat files** (e.g., `programs/desktop/hyprland.nix`, not `programs/desktop/hyprland [N]/hyprland.nix`)
  - `modules/services/` - Service features as **flat files in categorized subdirectories**:
    - `services/backup/` - syncthing.nix, syncthing-server.nix
    - `services/containers/` - docker.nix, podman.nix, docker-stremio.nix
    - `services/databases/` - mysql.nix, neo4j.nix
    - `services/monitoring/` - monitoring.nix, nix-healthchecks.nix, coolerd.nix
    - `services/networking/` - tailscale.nix, openvpn.nix, wireguard.nix, resolved.nix
    - `services/printing/` - printing.nix
    - `services/security/` - smb.nix
    - `services/system/` - fwupd.nix, flatpak.nix, bluetooth-receiver.nix
    - `services/tools/` - atuin.nix, croctalk.nix, ollama.nix, birthday.nix
  - `modules/factory/` - Factory aspects for parameterized features
  - `modules/hosts/` - Host-specific feature definitions (each host in its own directory)
  - `modules/users/` - User-specific features as **flat files**
- Features define **general modules** usable by any NixOS system
- Users can import and customize features through home-manager integration
- Migrate ALL configuration into `modules/` directory:
  - `parts/` → `modules/nix/flake-parts/` (migrate all parts to dendritic modules)
  - `hosts/` → `modules/hosts/` (host configurations become host features)
  - `profiles/` → `modules/system/system types/` (profiles become system type features)
- **Final directory structure**: Only 3 top-level directories:
  - `modules/` - All dendritic features (includes parts, hosts, profiles)
  - `secrets/` - Agenix encrypted secrets
  - `overlays/` - Nixpkgs overlays
- Remove `variables.nix` pattern, replace with dendritic best practices:
  - User preferences → User feature customizations
  - Git config → Constants Aspect or user feature
  - Program choices → Feature composition in user/host modules
- Add dendritic tools:
  - `vic/flake-file` for automatic flake.nix generation
  - `vic/import-tree` for automatic feature discovery
- **Scope**: NixOS configuration only - Home-Manager stays as-is for now

## Impact

### Structural Simplifications

This migration includes three key structural simplifications:

#### 1. Flat File Structure (No Subdirectories per Module)
**Before**: `modules/services/atuin [N]/atuin.nix`  
**After**: `modules/services/atuin.nix`

- One file per module, no extra directory nesting
- Cleaner navigation and simpler file paths
- Standard Nix convention
- Subdirectories only for logical grouping (e.g., `programs/cli/`, `programs/desktop/`)

#### 2. Remove All [N]/[D]/[ND] Markers
**Before**: `modules/services/docker [N]/`, `modules/hosts/gaming-casper [N]/`  
**After**: `modules/services/docker.nix`, `modules/hosts/gaming-casper/`

- Platform markers removed from file/directory names
- Cleaner, less cluttered appearance
- Platform specificity handled by module content, not naming
- Exception: Hosts remain in subdirectories (multiple files: configuration.nix, hardware.nix, flake-parts.nix)

#### 3. Service Categorization with Subdirectories

**Pattern**: Services organized in functional subdirectories as flat files

```
modules/services/
├── backup/
│   ├── syncthing.nix
│   └── syncthing-server.nix
│
├── containers/
│   ├── docker.nix
│   ├── podman.nix
│   └── docker-stremio.nix
│
├── databases/
│   ├── mysql.nix
│   └── neo4j.nix
│
├── monitoring/
│   ├── monitoring.nix
│   ├── nix-healthchecks.nix
│   └── coolerd.nix
│
├── networking/
│   ├── tailscale.nix
│   ├── openvpn.nix
│   ├── wireguard.nix
│   └── resolved.nix
│
├── printing/
│   └── printing.nix
│
├── security/
│   └── smb.nix
│
├── system/
│   ├── bluetooth-receiver.nix
│   ├── fwupd.nix
│   └── flatpak.nix
│
└── tools/
    ├── atuin.nix
    ├── birthday.nix
    ├── croctalk.nix
    └── ollama.nix
```

**Categories** (actual implementation):
- `backup/` - File synchronization services (syncthing, syncthing-server)
- `containers/` - Container runtimes and container services (docker, podman, docker-stremio)
- `databases/` - Database services (mysql, neo4j)
- `monitoring/` - System monitoring and health checks (monitoring, nix-healthchecks, coolerd)
- `networking/` - VPN, DNS, network services (tailscale, openvpn, wireguard, resolved)
- `printing/` - Print services (printing)
- `security/` - SMB file sharing (smb)
- `system/` - System update services, bluetooth audio receiver (bluetooth-receiver, fwupd, flatpak)
- `tools/` - User tools, shell history, AI services, notifications (atuin, birthday, croctalk, ollama)

Benefits:
- Clear functional grouping
- Easy to find related services
- Logical organization without excessive nesting
- One level of subdirectories (not too deep)
- Extensible for future services

## Impact

### Affected Specs
- **flake-structure**: Complete restructure of directory layout and module organization
- **nixos-configurations**: How hosts are defined and configured

### Affected Code
- **Root level**:
  - `flake.nix` - Already uses flake-parts, update to add dendritic tools (flake-file, import-tree)
  - **`parts/` directory** - ❌ REMOVED: Migrate all to `modules/nix/flake-parts/`
    - `parts/systems.nix` → `modules/nix/flake-parts/systems.nix`
    - `parts/formatter.nix` → `modules/nix/flake-parts/formatter.nix`
    - `parts/overlays.nix` → `modules/nix/flake-parts/lib.nix` (helper functions)
    - `parts/nixos.nix` → Remove (replaced by host features + flake-parts module)
    - `parts/home-manager.nix` → Remove or adapt for user features
  - `secrets/` - Keep as-is
  - `overlays/` - Keep as-is
- **modules/ directory** (complete restructure with **flat file layout**):
  - `modules/nix/` - Nix tooling (systems, formatter, lib)
  - `modules/system/` - System settings as **flat files** (locale.nix, boot.nix, networking.nix, graphics.nix, audio.nix, bluetooth.nix, xserver.nix, openssh.nix, nixpkgs.nix)
  - `modules/programs/` - **Flat files in categorized subdirectories**:
    - `programs/desktop/hyprland.nix` - Hyprland desktop
    - `programs/desktop/gnome.nix` - GNOME desktop
    - `programs/desktop/kde.nix` - KDE desktop
    - `programs/desktop/cosmic.nix` - Cosmic desktop
    - `programs/cli/tools.nix` - CLI tools collection
    - `programs/dev/git.nix` - Git and version control
    - `programs/dev/languages.nix` - Programming language tools
    - `programs/dev/lsp.nix` - Language servers
    - `programs/gaming/gaming.nix` - Gaming packages
    - `programs/gaming/steam.nix` - Steam
    - `programs/gaming/retroarch.nix` - RetroArch
    - `programs/gui/apps.nix` - GUI applications collection
    - `programs/gui/chromium.nix` - Chromium browser
    - `programs/gui/spotify.nix` - Spotify
    - `programs/gui/bambu-labs.nix` - Bambu Labs tools
    - `programs/work/technative.nix` - Work-specific tools
    - `programs/server/tools.nix` - Server utilities
    - `programs/system/hardware-utils.nix` - Hardware utilities
    - `programs/system/disk-utils.nix` - Disk utilities
    - `programs/system/fonts.nix` - Font packages
    - `programs/system/nix-ld.nix` - Nix-ld
    - `programs/system/rapid7.nix` - Rapid7 tools
  - `modules/services/` - Service features as **flat files** (23 services as .nix files)
  - `modules/factory/` - Factory aspects (user, mount, etc.)
  - `modules/hosts/` - Host feature definitions (each host in subdirectory: gaming-casper/, personal-casper/, server-casper/, technative-casper/)
  - `modules/users/` - User-specific customizations as **flat files** (casper.nix)
  - `modules/etc/` → ❌ REMOVED: Migrate to appropriate program/system categories
- **hosts/ directory** - ❌ REMOVED: Migrate to `modules/hosts/`
  - `hosts/<hostname>/default.nix` → `modules/hosts/<hostname>/configuration.nix`
  - `hosts/<hostname>/hardware-configuration.nix` → `modules/hosts/<hostname>/hardware.nix`
  - `hosts/<hostname>/variables.nix` → ❌ REMOVED: Replace with dendritic patterns
  - **Profile imports absorbed**: Each host feature directly imports the services/packages it needs
  - **Flat file structure**: No `[N]` markers, just clean directory names
- **profiles/ directory** - ❌ REMOVED: Logic absorbed into host features
  - `profiles/Work/` = `technative-casper` host
  - `profiles/Gaming/` = `gaming-casper` host  
  - `profiles/Personal/` = `personal-casper` host
  - `profiles/Server/` = `server-casper` host
  - No separate system types needed - each host is already specialized
- **home/ directory**: Kept as-is (not migrated in this change)

**Result**: Only 3 top-level directories remain: `modules/`, `secrets/`, `overlays/`

### Migration Strategy

The migration will follow a phased approach to minimize disruption:

1. **Phase 1: Infrastructure** - Add dendritic tools, migrate parts/, create modules/ structure
2. **Phase 2: Core System Features** - Nix settings, base system features, constants
3. **Phase 3: Services & Settings** - Migrate services, settings, hardware features
4. **Phase 4: Programs & Packages** - Migrate program and package features
5. **Phase 5: Factory Aspects** - Create user and mount factories
6. **Phase 6: Hosts** - Migrate hosts/ to host features (absorb profile logic), eliminate variables.nix
7. **Phase 7: Cleanup** - Rename old directories to _old* for backup, finalize

**Note**: Profiles are redundant (Work=technative-casper, Gaming=gaming-casper, Personal=personal-casper, Server=server-casper). Profile logic will be absorbed directly into host features.

**Backup strategy**: Old directories will be renamed with `_old` prefix for safety:
- `parts/` → `_oldparts/`
- `hosts/` → `_oldhosts/`
- `profiles/` → `_oldprofiles/`

### Benefits
- Features become highly reusable across all hosts
- Adding new hosts requires minimal code (just compose features)
- General features usable by any NixOS system, customizable per user
- Platform independence foundation (ready for future Darwin support)
- Easier to understand: feature X is defined in `modules/<category>/X/`
- Reduced code duplication by 60-70% (estimated)
- Faster troubleshooting: one feature, one location
- Clear separation: general features vs user customizations
- **Simplified structure**: Only 3 top-level directories (modules/, secrets/, overlays/)
- **No more variables.nix**: Configuration through proper dendritic patterns
- **Safe migration**: Old directories preserved as _old* backups

### Risks
- **High complexity**: Large-scale refactor touching entire codebase
- **Learning curve**: Team needs to understand dendritic pattern and flake-parts
- **Migration time**: Estimated 2-4 weeks for complete migration
- **Potential breakage**: Careful testing required for each phase

### Mitigation
- Follow dendritic design patterns from Doc-Steve's guide
- Create comprehensive test strategy for each migration phase
- Document the new pattern with examples in repository
- Keep git history clean with logical, reversible commits
- Test each host after each phase before proceeding
- **Preserve old directories**: Rename to _old* instead of deleting for safety
