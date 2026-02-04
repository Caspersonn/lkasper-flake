# Change: Migrate Home-Manager to Dendritic Flake Pattern

## Why

The NixOS system configuration was successfully migrated to the Dendritic Pattern in the `migrate-to-dendritic-pattern` change, but Home-Manager configurations remain in the traditional `home/` directory structure. This creates:

- **Inconsistent architecture**: NixOS uses dendritic pattern, Home-Manager uses traditional structure
- **Limited reusability**: Home-Manager configurations cannot be easily composed with system features
- **Duplication**: Similar patterns repeated across home-manager modules
- **User coupling**: All home-manager configs in `home/` are specific to user `casper`, but stored as if they're generic
- **Poor discoverability**: Related system and user configurations are in different directory trees
- **Missed dendritic benefits**: Cannot use Multi-Context Aspects, Factory Aspects, or other dendritic patterns

The existing `home/` directory contains ~54 Nix files organized as:
- `home/desktop-environments/` - Desktop environment configs (gnome, hyprland)
- `home/programs/` - User program configs (git, zsh, tmux, neovim, etc.)
- `home/themes/` - Theming configurations (Gruvbox, Catppuccin)
- `home/default.nix` - Imports all programs and desktop environments

This migration will align Home-Manager with the dendritic pattern established in the NixOS migration, following the mipnix reference architecture where user-specific home-manager configurations live in `modules/users/casper/`.

## What Changes

- **BREAKING** Migrate `home/` directory to dendritic pattern under `modules/users/casper/`
- Move user-specific home-manager configurations to proper user module structure
- Apply dendritic aspect patterns to home-manager features:
  - **Simple Aspect**: Direct home-manager configuration modules
  - **Inheritance Aspect**: Compose home-manager features via imports in `home-manager.nix`
- Reorganize home-manager modules following dendritic conventions:
  - `modules/users/casper/` - User-specific home-manager features organized by category
    - Shell programs (zsh, tmux, atuin, fzf, etc.)
    - Development tools (git, neovim)
    - Desktop environments (hyprland, gnome)
    - Terminal emulators (kitty, ghostty)
    - Browsers (firefox, librewolf)
    - Media apps (vesktop, retroarch)
    - Utilities (dirtygit, rbw, smug)
    - Themes (gruvbox, catppuccin)
- Enable home-manager features as `flake.modules.homeManager.<feature>` modules
- Create `modules/users/casper/home-manager.nix` to compose HM features via imports
- Integrate home-manager in each host's `configuration.nix` (following mipnix pattern)
- Remove traditional `home/` directory structure (rename to `_oldhome/` for safety)
- **Remove** `parts/home-manager.nix` - no longer needed with host-integrated approach

## Impact

### Affected Specs
- **home-manager-structure**: Complete restructure of home-manager module organization
- **user-configurations**: How user-specific home-manager configs are defined
- **flake-structure**: Continued alignment with dendritic pattern

### Affected Code
- **Root level**:
  - `home/` directory → **REMOVED**: Migrate all to `modules/users/casper/`
  - `parts/home-manager.nix` → **REMOVED**: No longer needed, HM integration in host configs
  - `modules/users/casper.nix` → Unchanged (system user account only)

- **New modules/users/casper/ structure**:
  - `modules/users/casper/home-manager.nix` - Composes all HM features via imports (following mipnix pattern)
  - `modules/users/casper/desktop/` - Desktop environment HM configs in subdirectories
    - `hyprland/default.nix`, `gnome/default.nix`
  - `modules/users/casper/programs/` - User programs in subdirectories
    - `zsh/`, `tmux/`, `git/`, `neovim/`, `kitty/`, `ghostty/`, `firefox/`, `librewolf/`, `vesktop/`, `retroarch/`, `dirtygit/`, `rbw/`, `smug/`, etc.
  - `modules/users/casper/themes/` - Theme configs in subdirectories
    - `gruvbox/default.nix`, `catppuccin/default.nix`

- **Host configuration updates** (each host in `modules/hosts/<hostname>/configuration.nix`):
  - Add `flake.homeConfigurations."casper@<hostname>"` declaration
  - Import user's `home-manager.nix` module: `pim` (from mipnix example)

### Migration Strategy

The migration will follow a phased approach aligned with dendritic principles:

1. **Phase 1: User Module Structure** - Create `modules/users/casper/home-manager.nix` and establish patterns
2. **Phase 2: Core Programs** - Migrate shell programs (zsh, tmux) and development tools (git, neovim) as individual feature modules
3. **Phase 3: Desktop Environments** - Migrate hyprland and gnome home-manager configs
4. **Phase 4: Additional Programs** - Migrate remaining programs (browsers, terminal, media, utils)
5. **Phase 5: Themes** - Migrate theme configurations
6. **Phase 6: Host Integration** - Add `flake.homeConfigurations` to each host's `configuration.nix`
7. **Phase 7: Cleanup** - Remove `parts/home-manager.nix`, rename `home/` to `_oldhome/` for backup

**Backup strategy**: Old directory will be renamed with `_old` prefix for safety:
- `home/` → `_oldhome/`
- `parts/home-manager.nix` → deleted (centralized approach no longer needed)

### Benefits
- **Architectural consistency**: Both NixOS and Home-Manager use dendritic pattern
- **Clear user ownership**: User-specific configs explicitly under `modules/users/casper/`
- **Better composition**: Home-manager features can be imported and composed like system features
- **Multi-Context capabilities**: Enable features that configure both system and home-manager in one module
- **Improved reusability**: Home-manager features can be extracted and reused for other users
- **Reduced duplication**: Common patterns shared across features
- **Better organization**: Related configs grouped by category (shell/, dev/, desktop/)
- **Future-ready**: Prepared for additional users (other family members, work profiles)
- **Safe migration**: Old directory preserved as `_oldhome/` backup

### Risks
- **Medium complexity**: Migrating ~54 home-manager modules
- **Configuration continuity**: Must preserve exact functionality during migration
- **Path dependencies**: Some programs may reference paths in home/ directory
- **Host integration changes**: Each host needs `flake.homeConfigurations` declaration added

### Mitigation
- Follow mipnix reference architecture for user module patterns
- Use existing NixOS dendritic migration as template
- Test each phase incrementally
- Preserve old directory as `_oldhome/` for easy rollback
- Document new patterns clearly
- Keep git history clean with logical commits
