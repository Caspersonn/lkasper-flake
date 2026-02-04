# Project Context

## Purpose
Personal NixOS configuration repository managing multiple machines using flakes and home-manager. This repository provides declarative system configurations for work, gaming, server, and personal machines with flexible desktop environment support.

## Tech Stack
- **NixOS** with flakes (following latest stable nixos)
- **flake-parts** for modular flake organization with dendritic pattern
- **vic/import-tree** for automatic feature discovery
- **home-manager** (following latest stable nixos) for dotfiles and user environment management
- **agenix** for encrypted secrets management
- **Desktop Environments**: Hyprland (primary), GNOME, KDE Plasma, Cosmic
- **Hyprland** as primary desktop environment.
    - **stylix** for system-wide theming
- **Multiple nixpkgs channels**: stable (25.11), 24.05, and unstable
- **Custom packages**: Integration with custom tools
    - bmc and race (AWS IAC tools from TechNative)
- **OpenSpec** for change management and proposals
- **Terminal emulators:**
    - ghostty (primary)
- **Shell:** zsh (primary)
- **tmux:**
    - tmux heavily customized
    - smug for declarative session configuration

## Managed Hosts

### Active machines
- **gaming-casper**: Personal gaming PC (x86_64)
- **personal-casper**: Laptop for personal use (x86_64)
- **technative-casper**: Laptop for work (x86_64)
- **server-casper**: raspbery pi 4 (aarch64)

## Recent Architectural Changes

### Dendritic Pattern Migration (Completed: 2026-02-03)
Successfully migrated the entire NixOS configuration to the Dendritic Pattern, achieving a bottom-up feature composition architecture:

**Key Changes**:
- Migrated from top-down (hosts have features) to bottom-up (features imported by hosts)
- Restructured all configuration into `modules/` directory with 68 reusable feature modules
- Features are simple NixOS modules enabled by importing (no `mkEnableOption` flags)
- Automatic feature discovery via `vic/import-tree`
- Self-contained host configurations that declare their own `nixosConfiguration`
- Flat file structure with logical categorization (no `[N]` directory markers)
- Extracted common system configuration into 10 reusable system modules

**Directory Structure** (after migration):
```
lkasper-flake/
├── flake.nix              # Uses import-tree for auto-discovery
├── modules/               # All dendritic features (68 modules)
│   ├── nix/              # Flake infrastructure
│   ├── system/           # System configuration (10 modules)
│   ├── hardware/         # Hardware-specific (5 modules)
│   ├── programs/         # Programs by type (22 modules)
│   ├── services/         # Services by function (23 modules in 9 categories)
│   ├── hosts/            # 4 self-contained host configurations
│   └── users/            # User modules
├── secrets/              # Agenix secrets
├── home/                 # Home-Manager (not yet migrated)
├── _oldParts/            # Old way of using flake parts
├── _oldProfiles/         # Old mk.if cfg way to manage my imports of modules
└── _oldHosts             # Old host folder with all Machines configurations
```

**Benefits**:
- Superior code reusability across all hosts
- Simplified troubleshooting (one feature = one location)
- Enhanced maintainability (add/remove features via imports)
- Better modularity (self-contained modules)
- Reduced code duplication by ~60-70%
- Foundation for future Darwin (macOS) support

**References**:
- See `openspec/changes/migrate-to-dendritic-pattern/` for full design and implementation details
- Pattern based on [mipnix](https://github.com/mipmip/mipnix) and [dendritic-design](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)

## Project Conventions

### Code Style
- **Formatter**: nixfmt-classic (not used)
- **File naming**: kebab-case for files (e.g., `service-docker.nix`, `desktop-hyprland.nix`)
- **Module naming**: Descriptive prefixes (service-, pkgs-, desktop-)
- **Allow unfree packages**: Enabled globally in overlays

### Architecture Patterns
- **Dendritic Pattern**: Bottom-up feature composition using flake-parts
  - Features are simple NixOS modules enabled by importing (not by option flags)
  - Automatic feature discovery via `vic/import-tree`
  - Import-based composition: `imports = with inputs.self.modules.nixos; [feature1 feature2 ...]`
  - **68 reusable feature modules** organized by category
- **Module Organization**: All configuration centralized in `modules/` directory
  - `modules/nix/`: Nix tooling and flake infrastructure
  - `modules/system/`: System-level configuration (10 modules: locale, boot, networking, graphics, audio, bluetooth, xserver, openssh, nixpkgs, etc.)
  - `modules/hardware/`: Hardware-specific modules (5 modules: Framework, udev rules)
  - `modules/programs/`: Program features organized by type (22 modules)
    - `programs/desktop/`: Desktop environments (hyprland, gnome, kde, cosmic)
    - `programs/cli/`: CLI tools
    - `programs/dev/`: Development tools (git, languages, lsp)
    - `programs/gaming/`: Gaming programs
    - `programs/gui/`: GUI applications
    - `programs/work/`: Work-specific tools
    - `programs/server/`: Server tools
    - `programs/system/`: System utilities
  - `modules/services/`: Service features organized by function (23 modules in 9 categories)
    - `services/backup/`: File sync (syncthing)
    - `services/containers/`: Container runtimes (docker, podman)
    - `services/databases/`: Databases (mysql, neo4j)
    - `services/monitoring/`: System monitoring
    - `services/networking/`: VPN and network services (tailscale, openvpn, wireguard)
    - `services/printing/`: Print services
    - `services/security/`: SMB file sharing
    - `services/system/`: System services (fwupd, flatpak, bluetooth-receiver)
    - `services/tools/`: Utilities (atuin, ollama, croctalk, birthday)
  - `modules/hosts/`: Self-contained host configurations (4 hosts)
  - `modules/users/`: User-specific features
- **Flat file structure**: Features are flat `.nix` files in categorized subdirectories (no `[N]` markers)
- **Self-contained hosts**: Each host declares its own `nixosConfiguration` and composes features via imports
- **Home-manager integration**: User environment managed in `home/` (not yet migrated to dendritic pattern)
- **Helper functions**: `makeNixos` for DRY host configuration
- **Overlay system**: Custom package overrides in `overlays/default.nix`
- **Multi-architecture support**: x86_64-linux and aarch64-linux

### Testing Strategy
- Manual testing on actual hardware
- Flake checks ensure configuration validity
- Build configurations before deployment
- Test changes on non-critical machines first

### Git Workflow
- **Main branch**: `main`
- **Commit style**: Descriptive commit messages (see recent commits for examples)
- **Feature workflow**: Direct commits to main for personal use
- **OpenSpec integration**: Use OpenSpec change proposals for architectural changes
- **Dendritic pattern**: Features composed through imports, not enabled via option flags

## Important Constraints
- **NixOS-only**: All configuration must be valid Nix expressions
- **Flakes required**: Pure flake evaluation (no impure operations)
- **Dendritic pattern**: Features are simple NixOS modules, enabled by importing (not by option flags)
- **Automatic discovery**: All modules must be git-tracked for `import-tree` to discover them
- **File structure**: Modules wrapped with `{ inputs, ... }:` for import-tree compatibility
- **Secrets management**: Sensitive data must use agenix, never committed in plain text
- **Reproducibility**: Configurations must be deterministic and reproducible
- **Unfree packages**: Some proprietary software is allowed (configured in overlays)
- **Framework hardware**: technative-casper machine requires nixos-hardware.nixosModules.framework-13-7040-amd

## External Dependencies
- **GitHub repositories**: Multiple flake inputs from various sources
- **vic/import-tree**: Automatic feature discovery for dendritic pattern
- **flake-parts**: Modular flake organization framework
- **TechNative services**: Internal company tools (bmc, race, croctalk, slack2zammad, monitoring)
- **Nixpkgs channels**: Tracks stable (25.11, 24.05) and unstable branches
- **Tailscale**: VPN for machine interconnection (not being used)
- **Docker/Podman**: Container runtime for services
- **agenix encrypted secrets**: Age-encrypted files for sensitive configuration
