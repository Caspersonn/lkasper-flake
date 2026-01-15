# Project Context

## Purpose
Personal NixOS configuration repository managing multiple machines using flakes and home-manager. This repository provides declarative system configurations for work, gaming, server, and personal machines with flexible desktop environment support.

## Tech Stack
- **NixOS** with flakes (following latest stable nixos)
- **home-manager** (following latest stable nixos) for dotfiles and user environment management
- **agenix** for encrypted secrets management
- **Desktop Environments**: Hyprland (primary), GNOME, KDE Plasma, Cosmic
- **Hyprland** as primary desktop environment.
    - **stylix** for system-wide theming
- **Multiple nixpkgs channels**: stable (25.11), 24.05, and unstable
- **Custom packages**: Integration with custom tools 
    - bmc and race (AWS IAC tools from TechNative
- **OpenSpec** for change management and proposals
- **Terminal emulators:**
    - ghostty (primary)
- **Shell:** zsh (primary)
- **tmux:**
    - tmux heavily custimized
    - smug for declaritive session configuration

## Managed Hosts

### Active machines
- **gaming-casper**: Personal gaming PC (x86_64)
- **personal-casper**: Laptop for personal use (x86_64)
- **technative-casper**: Laptop for work (x86_64)
- **server-casper**: raspbery pi 4 (aarch64)

## Project Conventions

### Code Style
- **Formatter**: nixfmt-classic (not used)
- **File naming**: kebab-case for files (e.g., `service-docker.nix`, `desktop-hyprland.nix`)
- **Module naming**: Descriptive prefixes (service-, pkgs-, desktop-)
- **Allow unfree packages**: Enabled globally in overlays

### Architecture Patterns
- **Modular structure**: Reusable modules organized by category
  - `modules/services/`: System services (Docker, Tailscale, OpenVPN, etc.)
  - `modules/packages/`: Package collections and custom builds
  - `modules/desktop-environments/`: Desktop environment configurations
  - `modules/etc/`: Miscellaneous system configuration (udev rules, secrets)
- **Profile-based configuration**: Machine types defined in `profiles/` (Work, Gaming, Server, Personal)
- **Host-specific configs**: Hardware and machine-specific settings in `hosts/`
- **Home-manager integration**: User environment managed alongside system configuration
- **Helper functions**: `makeHomeConf` and `makeNixosConf` for DRY configuration
- **Role-based desktop selection**: Boolean flags (gnome, hyprland, cosmic, kde) control desktop environment
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
- **OpenSpec integration**: Use `/openspec:proposal` for architectural changes

## Important Constraints
- **NixOS-only**: All configuration must be valid Nix expressions
- **Flakes required**: Pure flake evaluation (no impure operations)
- **Secrets management**: Sensitive data must use agenix, never committed in plain text
- **Reproducibility**: Configurations must be deterministic and reproducible
- **Unfree packages**: Some proprietary software is allowed (configured in overlays)
- **Framework hardware**: technative-casper machine requires nixos-hardware.nixosModules.framework-13-7040-amd

## External Dependencies
- **GitHub repositories**: Multiple flake inputs from various sources
- **TechNative services**: Internal company tools (bmc, race, croctalk, slack2zammad, monitoring)
- **Nixpkgs channels**: Tracks stable (25.11, 24.05) and unstable branches
- **Tailscale**: VPN for machine interconnection (not being used)
- **Docker/Podman**: Container runtime for services
- **agenix encrypted secrets**: Age-encrypted files for sensitive configuration
