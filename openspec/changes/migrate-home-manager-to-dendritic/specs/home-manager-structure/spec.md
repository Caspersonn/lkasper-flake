## MODIFIED Requirements

### Requirement: Home-Manager Module Organization

The home-manager configuration SHALL be organized following the dendritic pattern with user-scoped module structure under `modules/users/<username>/`.

#### Scenario: User home-manager features are discoverable

- **WHEN** home-manager features are defined for a user
- **THEN** they SHALL be organized under `modules/users/<username>/` directory
- **AND** each feature SHALL expose `flake.modules.homeManager.<username>-<feature>`
- **AND** features SHALL be automatically discovered via import-tree

#### Scenario: User module imports home-manager features

- **WHEN** a user module defines home-manager configuration
- **THEN** it SHALL import features using `imports = with inputs.self.modules.homeManager; [...]`
- **AND** features SHALL be prefixed with username (e.g., `casper-zsh`, `casper-git`)
- **AND** user module SHALL set `home.stateVersion`

#### Scenario: Home-manager features are categorized

- **WHEN** home-manager features are organized
- **THEN** they SHALL be grouped into logical categories
- **AND** categories SHALL include: desktop/, programs/, themes/
- **AND** programs SHALL be further categorized: shell/, dev/, terminal/, browsers/, media/, utils/

## REMOVED Requirements

### Requirement: Traditional home/ Directory Structure

**Reason**: Replaced with dendritic pattern under modules/users/<username>/

**Migration**: 
- Move `home/desktop-environments/` → `modules/users/casper/desktop/`
- Move `home/programs/` → `modules/users/casper/programs/`
- Move `home/themes/` → `modules/users/casper/themes/`
- Replace `home/default.nix` imports with explicit feature imports in user module
- Rename `home/` → `_oldhome/` for backup
