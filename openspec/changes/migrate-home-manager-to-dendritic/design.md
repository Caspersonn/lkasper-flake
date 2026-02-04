# Design: Home-Manager Dendritic Pattern Migration

## Context

The NixOS system configuration was successfully migrated to the Dendritic Pattern in `migrate-to-dendritic-pattern`, establishing:
- Feature-based composition using `flake.modules.nixos.*`
- Automatic discovery with `vic/import-tree`
- 4 hosts configured as dendritic modules in `modules/hosts/`
- System features in `modules/system/`, `modules/programs/`, `modules/services/`
- User account module at `modules/users/casper.nix`

**Current Home-Manager structure**:
- Traditional directory-based organization in `home/`
- ~54 Nix files across desktop-environments/, programs/, themes/
- `home/default.nix` imports all programs via `builtins.readDir`
- Configurations are user-specific (casper) but stored generically
- Integrated per-host through `parts/home-manager.nix` (centralized)

**What's missing for dendritic pattern**:
- No `flake.modules.homeManager.*` for home-manager features
- Home-manager configs not discoverable via import-tree
- User-specific nature not explicit in file structure
- Centralized `parts/home-manager.nix` instead of per-host integration
- No composition through imports pattern

**Reference architectures**:
- **mipnix**: https://github.com/mipmip/mipnix
  - User HM features in `modules/users/<username>/`
  - `home-manager.nix` composes features via imports
  - `flake.homeConfigurations` declared in each host's `configuration.nix`
  - No centralized parts/home-manager.nix needed

### Constraints
- Must maintain all current home-manager functionality
- Must preserve user customizations and settings
- Must work with existing NixOS dendritic structure
- Must support current host configurations (4 hosts)
- Home-manager configurations are specific to user `casper`
- **Preserve old directory** with _old prefix for safe migration

### Stakeholders
- Primary user (casper) - personal and work machines
- Future: potential additional users (family members, work profiles)

## Goals / Non-Goals

### Goals
- Migrate home-manager to dendritic pattern under `modules/users/casper/`
- Apply appropriate dendritic aspect patterns to home-manager features
- Enable home-manager feature composition through imports
- Integrate HM per-host (following mipnix pattern)
- Remove centralized `parts/home-manager.nix`
- Maintain architectural consistency with NixOS dendritic pattern
- **Safely preserve old directory** as _oldhome/ backup

### Non-Goals
- Refactoring individual home-manager configurations (keep current settings)
- Creating additional user profiles (focus on casper only)
- Migrating to different home-manager modules or frameworks
- Changing desktop environment or program functionality
- Permanently deleting old directory (rename to _oldhome/ for safety)

## Decisions

### Decision 1: User Home-Manager Structure with Subdirectories

**Pattern**: Home-manager features organized in subdirectories under `modules/users/casper/`

**Structure**:
```
modules/users/
├── casper.nix                    # System user account (unchanged)
└── casper/
    ├── home-manager.nix          # Composes all HM features via imports
    ├── desktop/                  # Desktop environments
    │   ├── hyprland/             # Hyprland HM config (complex with waybar, etc.)
    │   │   └── default.nix
    │   └── gnome/                # GNOME HM config
    │       └── default.nix
    ├── programs/                 # User programs
    │   ├── zsh/
    │   │   └── default.nix
    │   ├── tmux/
    │   │   └── default.nix
    │   ├── git/
    │   │   └── default.nix
    │   ├── neovim/
    │   │   └── default.nix
    │   ├── kitty/
    │   │   └── default.nix
    │   ├── ghostty/
    │   │   └── default.nix
    │   ├── firefox/
    │   │   └── default.nix
    │   ├── librewolf/
    │   │   └── default.nix
    │   ├── vesktop/
    │   │   └── default.nix
    │   ├── retroarch/
    │   │   └── default.nix
    │   ├── dirtygit/
    │   │   └── default.nix
    │   ├── rbw/
    │   │   └── default.nix
    │   ├── smug/
    │   │   └── default.nix
    │   ├── atuin/
    │   │   └── default.nix
    │   ├── fzf/
    │   │   └── default.nix
    │   └── ... (other programs)
    └── themes/                   # Themes
        ├── gruvbox/
        │   └── default.nix
        └── catppuccin/
            └── default.nix
```

**Why**:
- Preserves existing organizational structure from `home/`
- Clear categorization: desktop/, programs/, themes/
- Each program in its own subdirectory with default.nix
- Easier to include config files, scripts, or assets with the program
- Maintains consistency with current approach
- All features automatically discovered via import-tree

**Reference**: Maintains current `home/` structure while adapting to dendritic pattern

### Decision 2: home-manager.nix Composes Features

**Pattern**: Single `home-manager.nix` file that imports all HM features

**Example**:
```nix
# modules/users/casper/home-manager.nix
{ inputs, self, ... }: {
  
  flake.modules.homeManager.casper = {
    
    imports = with inputs.self.modules.homeManager; [
      # Shell programs
      casper-zsh
      casper-tmux
      casper-atuin
      casper-fzf
      casper-zoxide
      
      # Development
      casper-git
      casper-neovim
      
      # Desktop (conditional per host)
      casper-hyprland
      # casper-gnome
      
      # Terminal
      casper-kitty
      
      # Browsers
      casper-firefox
      
      # Media
      casper-vesktop
      
      # Utilities
      casper-dirtygit
      casper-rbw
      casper-smug
      
      # Theme
      casper-gruvbox
    ];
    
    nixpkgs.config.allowUnfree = true;
  };
}
```

**Why**:
- Central composition point for user's HM features
- Similar to mipnix `pim/home-manager.nix`
- Exposes `flake.modules.homeManager.casper` for hosts to use
- Features enabled by importing them (not by enable flags)

**Reference**: https://github.com/mipmip/mipnix/blob/main/modules/users/pim/home-manager.nix

### Decision 3: Per-Host Home-Manager Integration

**Pattern**: Each host declares `flake.homeConfigurations` in its `configuration.nix`

**Example**:
```nix
# modules/hosts/technative-casper/configuration.nix
{ inputs, self, ... }:

let
  hostname = "technative-casper";
in
{
  # Declare homeConfiguration for this host
  flake.homeConfigurations = {
    "casper@technative-casper" = self.lib.makeHomeConf {
      inherit hostname;
      # Import the user's home-manager module
      imports = with inputs.self.modules.homeManager; [
        casper
      ];
    };
  };

  # NixOS configuration for this host
  flake.nixosConfigurations = {
    technative-casper = self.lib.makeNixos {
      inherit hostname;
      system = "x86_64-linux";
    };
  };

  # Host module definition
  flake.modules.nixos.technative-casper = { config, pkgs, ... }: {
    imports = with inputs.self.modules.nixos; [
      # System features
      tailscale
      docker
      hyprland
      # ...
    ];
    
    networking.hostName = "technative-casper";
    system.stateVersion = "25.11";
  };
}
```

**Why**:
- Follows mipnix pattern exactly
- Each host self-contained (declares both NixOS and HM configs)
- No centralized `parts/home-manager.nix` needed
- Automatic discovery via import-tree
- Host-specific HM configurations possible

**Reference**: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/configuration.nix

### Decision 4: Remove parts/home-manager.nix

**Decision**: Delete `parts/home-manager.nix` - no longer needed

**Why**:
- Centralized HM integration replaced by per-host approach
- Each host declares its own `flake.homeConfigurations`
- Simpler, more explicit, aligns with dendritic pattern
- Follows mipnix architecture (no central HM parts file)

### Decision 5: Individual Feature Modules

**Pattern**: Each HM feature as `flake.modules.homeManager.<feature>` module

**Example - Program feature**:
```nix
# modules/users/casper/programs/zsh/default.nix
{ inputs, ... }: {
  flake.modules.homeManager.casper-zsh = {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      # ... existing zsh config
    };
  };
}
```

**Example - Desktop feature**:
```nix
# modules/users/casper/desktop/hyprland/default.nix
{ inputs, ... }: {
  flake.modules.homeManager.casper-hyprland = {
    wayland.windowManager.hyprland = {
      enable = true;
      # ... hyprland config
    };
    programs.waybar = {
      # ... waybar config
    };
    # ... other hyprland-related configs
  };
}
```

**Structure approach**:
- ALL features in subdirectories with `default.nix`
- Matches existing `home/` organization
- Each directory can contain config files, scripts, assets
- Example: `programs/zsh/`, `desktop/hyprland/`, `themes/gruvbox/`

**Why**:
- Balances simplicity with organization
- Follows established NixOS dendritic migration pattern
- Clear: one file = simple, directory = complex

### Decision 6: Naming Convention

**Pattern**: Prefix all HM features with username: `casper-<feature>`

**Examples**:
- `casper-zsh` - ZSH configuration
- `casper-hyprland` - Hyprland HM config
- `casper-git` - Git configuration

**Why**:
- Makes user ownership explicit
- Avoids conflicts with system-level features
- Enables future multi-user support
- Clear distinction: system features vs user features

### Decision 7: makeHomeConf Helper Function

**Pattern**: Use existing `self.lib.makeHomeConf` helper for HM configurations

**Assumption**: Helper function exists or will be created in `modules/nix/lib/flake-parts.nix`

**Signature**:
```nix
makeHomeConf = {
  hostname,
  system ? "x86_64-linux",
  imports ? [],
  ...
}: home-manager.lib.homeManagerConfiguration {
  # ... implementation
};
```

**Why**:
- Consistent with `makeNixos` helper for NixOS configs
- Reduces boilerplate in host configurations
- Centralizes HM configuration logic

### Decision 8: Desktop Environment Handling

**Pattern**: Desktop HM features remain separate from system desktop modules

**Clarification**:
- System desktop (e.g., `modules/programs/desktop/hyprland.nix`) - Enables Hyprland system-wide
- User desktop (e.g., `modules/users/casper/casper-hyprland.nix`) - User-specific Hyprland settings

**Why**:
- Clear separation of system vs user configuration
- User can customize desktop without affecting system config
- Follows dendritic pattern of feature composition

### Decision 9: Import-Tree Discovery

**Pattern**: All HM features automatically discovered via import-tree

**Requirements**:
- Files must have `{ inputs, ... }:` or `{ inputs, self, ... }:` wrapper
- Files must be git-tracked
- Define `flake.modules.homeManager.<feature>` inside files

**Why**:
- Consistent with NixOS dendritic pattern
- Automatic discovery eliminates manual imports
- Features available when added to modules/users/casper/

### Decision 10: Theme Organization

**Pattern**: Themes as separate HM features

**Example**:
```nix
# modules/users/casper/casper-gruvbox.nix
{ inputs, ... }: {
  flake.modules.homeManager.casper-gruvbox = {
    # Stylix or theme configuration
    # Color schemes, fonts, etc.
  };
}
```

**Why**:
- Themes are user preferences
- Easy to switch themes via imports in home-manager.nix
- Separate from programs for clarity

### Decision 11: Migration Phases

**Phase approach**:
1. **User Module Structure** - Create `home-manager.nix`, establish patterns
2. **Core Programs** - Shell + dev tools (most used)
3. **Desktop Environments** - Hyprland, GNOME HM configs
4. **Additional Programs** - Browsers, terminal, media, utils
5. **Themes** - Theme configurations
6. **Host Integration** - Add `flake.homeConfigurations` to each host
7. **Cleanup** - Delete `parts/home-manager.nix`, rename `home/` to `_oldhome/`

**Why**:
- Incremental approach reduces risk
- Core programs first enables basic functionality
- Can test each phase before proceeding

### Decision 12: Preserve Old Directory as Backup

**Strategy**: Rename to _oldhome/ instead of deleting

**Commands**:
```bash
mv home _oldhome
rm parts/home-manager.nix  # No longer needed
echo "_old*/" >> .gitignore
```

**Why**: Safety, easy rollback, can verify before permanent removal

## Migration Plan

### Phase 1: User Module Structure (1 day)
Create `home-manager.nix`, establish patterns, create first feature

### Phase 2: Core Programs (2-3 days)
Shell programs (zsh, tmux, atuin, fzf) and dev tools (git, neovim)

### Phase 3: Desktop Environments (2-3 days)
Hyprland and GNOME home-manager configurations

### Phase 4: Additional Programs (2-3 days)
Browsers, terminal, media, utilities

### Phase 5: Themes (1 day)
Theme configurations

### Phase 6: Host Integration (1-2 days)
Add `flake.homeConfigurations` to each host's `configuration.nix`

### Phase 7: Cleanup (1 day)
Delete `parts/home-manager.nix`, rename `home/` to `_oldhome/`, update documentation

**Total estimated time**: 10-15 days (2-3 weeks)

## Risks / Trade-offs

- Home-manager configs complex → Mitigate with phased approach
- Per-host integration changes → Clear template from mipnix reference
- Path dependencies in configs → Update paths during migration
- Safe rollback available via _oldhome/ directory

## Open Questions

None - pattern is clearly defined by mipnix reference architecture
