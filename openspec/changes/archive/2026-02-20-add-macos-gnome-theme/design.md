# Design: macOS-like GNOME Theme

## Context
User Antonia needs a production-ready GNOME desktop environment that mimics macOS Big Sur aesthetics and workflow. The existing GNOME module is empty. This change implements a comprehensive theme based on WhiteSur suite (GTK theme, icons, cursors) and gnomintosh project patterns.

## Goals / Non-Goals

### Goals
- Declarative, reproducible GNOME theme configuration via home-manager
- macOS-like visual appearance (windows, dock, icons, cursors)
- macOS-like behavior (dock position, animations, workspace navigation)
- Proper NixOS package derivations for all theme components
- Support for both GTK3 and GTK4/libadwaita applications

### Non-Goals
- System-level GNOME installation (user responsibility)
- GDM theme customization (requires system-level config)
- Firefox theme integration (separate concern)
- Dash-to-Panel alternative (using Dash-to-Dock for macOS-like bottom dock)

## Decisions

### Package Structure
- **Decision**: Create separate derivations for GTK theme, icons, and cursors
- **Why**: Each component is independently versioned and can be updated separately
- **Pattern**: Use `stdenv.mkDerivation` with `fetchFromGitHub`, install to `$out/share`

### Theme Application Method
- **Decision**: Use home-manager's `dconf.settings` for all GNOME configuration
- **Why**: Declarative, version-controlled, reproducible across machines
- **Alternative considered**: Activation scripts with `gsettings` - rejected due to imperatives and poor reproducibility

### Extension Management
- **Decision**: Use home-manager's `programs.gnome-shell` for extension management
- **Why**: Native support for extension installation and configuration
- **Extensions required**:
  - `dash-to-dock` - macOS-like bottom dock
  - `user-themes@gnome-shell-extensions.gcampax.github.com` - custom shell themes
  - `just-perfection-desktop@just-perfection` - UI customization

### Font Handling
- **Decision**: Include Inter font (similar to SF Pro) instead of proprietary SF Pro
- **Why**: SF Pro requires Apple EULA acceptance, Inter is open-source and visually similar
- **Alternative**: Document how users can manually install SF Pro if desired

### Activation Script Strategy
- **Decision**: Use `home.activation` to symlink theme files from nix store to expected locations
- **Why**: GNOME expects themes in `~/.themes/`, icons in `~/.icons/`, dconf alone isn't sufficient
- **Pattern**: Check for existing files, create symlinks with proper permissions

## Theme Component Versions
- WhiteSur GTK theme: 2024-11-18 (latest stable)
- WhiteSur icons: 2023-06-16 (latest stable)
- WhiteSur cursors: 2024-06-02 (latest stable)

## Configuration Philosophy
- Dark theme by default (macOS dark mode equivalent)
- Dock centered at bottom, auto-hide on overlap, show on mouse hover
- Top bar minimal (no activities button, show app menu, centered clock)
- Window buttons on left (macOS style)
- Animations enabled with smooth transitions

## Risks / Trade-offs

### Risk: Theme update breakage
- **Mitigation**: Pin specific commit SHAs, test updates in staging environment

### Risk: dconf settings override user preferences
- **Mitigation**: Document which settings are managed, provide override mechanism via home-manager

### Risk: Extension incompatibility with GNOME updates
- **Mitigation**: Pin GNOME Shell version at system level, test extension compatibility before upgrading

### Trade-off: Inter vs SF Pro fonts
- **Impact**: Visual difference is minor, but power users may want actual SF Pro
- **Solution**: Document manual installation path for SF Pro in comments

## Migration Plan

### Initial Deployment
1. Build packages (whitesur-gtk, whitesur-icons, whitesur-cursors)
2. Deploy home-manager configuration to antonia@sakura
3. User logs out and logs back into GNOME
4. Theme applied automatically via dconf and activation scripts

### Rollback
- Revert home-manager configuration
- Run `dconf reset -f /` to clear GNOME settings (nuclear option)
- Or: Set GTK/icon themes back to Adwaita via dconf

## Open Questions
- Should we support light theme variant via option flag?
- Should we include Kvantum theme for Qt application consistency?
- Should wallpapers be included or left to user preference?
