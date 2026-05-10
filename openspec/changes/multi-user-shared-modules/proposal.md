# Change: Multi-User Separation with Shared Home-Manager Modules

## Why

All home-manager modules are currently tied to user `casper`, including work-specific tooling (TechNative AWS configs, terraform aliases, work packages). This creates several problems:

- **No work/personal separation**: Work aliases (`tfplan`, `aws-switch`, `bcd`) and personal configs are mixed in `casper-zsh`
- **Duplication across users**: `antonia-zsh` is nearly identical to `casper-zsh` (including TechNative aliases that don't belong there), `antonia-neovim` is identical to `casper-neovim`
- **System-wide work packages**: `modules/programs/work/technative.nix` installs ~50 work packages system-wide for all users, even on the gaming PC
- **Hardcoded paths**: Several modules reference `/home/casper/` instead of `$HOME` or `config.home.homeDirectory`
- **Inactive module clutter**: ~16 HM modules are registered but not imported (replaced by `omarchy-nix`)

The user wants a separate `lucak` user for work to achieve mental separation between work and personal contexts (logging out/in is the desired switch mechanism).

## What Changes

### 1. Create shared HM modules (Dendritic Simple Aspect)

Extract reusable configuration from `casper-*` modules into `shared-*` modules under `modules/users/shared/`. These contain base configuration without user-specific values (no git identity, no personal aliases, no user-specific profiles).

**Folder convention**: Only modules with accompanying config files get a directory (`zsh/`, `opencode/`, `dirty-repo-scanner/`). All others are single `.nix` files (`git.nix`, `fzf.nix`, `tmux.nix`).

**Modules to create** (16 shared modules):
- `shared-zsh` — base oh-my-zsh, autosuggestion, syntax highlighting, plugins (no aliases)
- `shared-git` — push/pull/merge/gh settings (no user.email/user.name)
- `shared-neovim` — nixvim package + EDITOR
- `shared-firefox` — base extensions: uBlock, Bitwarden, Return YT Dislikes (no profiles)
- `shared-fzf` — `programs.fzf.enable = true`
- `shared-zoxide` — `programs.zoxide.enable = true`
- `shared-autojump` — `programs.autojump.enable = true`
- `shared-atuin` — sync to atuin.inspiravita.com
- `shared-jq` — `programs.jq.enable = true`
- `shared-tmux` — gruvbox theme, tses shortcuts, plugins
- `shared-tses` — tmux sessionizer package
- `shared-font` — Nerd Fonts (FiraCode, JetBrains Mono, etc.)
- `shared-age` — agenix home-manager module import
- `shared-opencode` — opencode config (fix hardcoded `/home/casper` path)
- `shared-dirty-repo-scanner` — package + config.yml
- `shared-technative` — all TechNative work packages as `home.packages` (moved from system-wide `modules/programs/work/technative.nix`)

### 2. Refactor user modules using Inheritance Aspect

Instead of creating separate per-user modules for git/zsh/firefox, each user's `home-manager.nix` imports shared modules and overrides values inline (Dendritic Inheritance Aspect pattern). This eliminates the need for `casper-git`, `casper-zsh`, `casper-firefox`, `lucak-git`, `lucak-zsh`, `lucak-firefox` as separate modules.

**Example** — `casper/home-manager.nix` imports `shared-git` and overrides identity inline:
```nix
programs.git.settings.user = {
  email = "lucakasper8@gmail.com";
  name = "Caspersonn";
};
```

Per-user modules that remain as separate files (too complex for inline):
- `casper-nextcloud` — systemd service + timer + agenix secret (~40 lines)
- `casper-vesktop` — full vesktop + vencord config with themes (~35 lines)
- `casper-smug` — has accompanying config files (smug session YAMLs)
- `lucak-aws` — massive AWS profile generator with dynamic account mapping (~240 lines)

### 3. Create `lucak` user for work

New user under `modules/users/lucak/`:
- `nixos.nix` — user account definition (same SSH key as casper, same groups)
- `home-manager.nix` — imports shared modules + `shared-technative` + `lucak-aws`, overrides git identity, werk zsh aliases, werk Firefox profile

### 4. Simplify `antonia` using shared modules

Replace duplicate modules (`antonia-zsh`, `antonia-neovim`) with shared imports. Remove TechNative aliases from antonia's config (she's not a TechNative employee). Keep `antonia-git` identity and `gnome` desktop as overrides.

### 5. Update host configurations

Add `lucak` user and `lucak@hostname` homeConfiguration to:
- `gaming-casper` — both `casper` and `lucak`
- `personal-casper` — both `casper` and `lucak`
- `technative-casper` — both `casper` and `lucak`

### 6. Minimize system-wide `technative.nix`

Remove all packages (moved to `shared-technative` HM module). Keep only what's truly system-level:
- `security.acme` configuration
- `fonts.packages` for lato font (or move to shared-font)

### 7. Clean up inactive modules

Move ~16 unused modules to `_unused/` (ignored by `import-tree` via `/_` prefix):
- Legacy Hyprland HM modules (replaced by `omarchy-nix` `lkh-*` modules)
- Unused themes (`casper-catppuccin`, `casper-gruvbox`)
- Unused desktop configs (`casper-gnome`, `casper-kitty`, `casper-ghostty`, `casper-hyprland` wrapper)
- Unused antonia KDE config

### 8. Fix hardcoded paths

| Module | Problem | Fix |
|--------|---------|-----|
| `casper-aws` (becomes `lucak-aws`) | `builtins.path { path = /home/casper/.aws/... }` | Use `config.home.homeDirectory` |
| `casper-nextcloud` | `/home/casper/Documents` in ExecStart | Use `${config.home.homeDirectory}/Documents` |
| `casper-opencode` (becomes `shared-opencode`) | `/home/casper/git/personal/...` in plugin | Use `${config.home.homeDirectory}/git/personal/...` |

## Impact

### New file structure

```
modules/users/
├── shared/                              NEW: shared HM modules
│   ├── zsh/                             folder (has ohmyzsh theme dir)
│   │   ├── default.nix                  shared-zsh
│   │   └── ohmyzsh-casper/
│   ├── opencode/                        folder (has config/ dir)
│   │   ├── default.nix                  shared-opencode
│   │   └── config/
│   ├── dirty-repo-scanner/              folder (has config.yml)
│   │   ├── default.nix                  shared-dirty-repo-scanner
│   │   └── config.yml
│   ├── git.nix                          shared-git
│   ├── neovim.nix                       shared-neovim
│   ├── firefox.nix                      shared-firefox
│   ├── tmux.nix                         shared-tmux
│   ├── fzf.nix                          shared-fzf
│   ├── zoxide.nix                       shared-zoxide
│   ├── autojump.nix                     shared-autojump
│   ├── atuin.nix                        shared-atuin
│   ├── jq.nix                           shared-jq
│   ├── tses.nix                         shared-tses
│   ├── font.nix                         shared-font
│   ├── age.nix                          shared-age
│   └── technative.nix                   shared-technative (work packages)
│
├── casper/
│   ├── nixos.nix                        UNCHANGED
│   ├── home-manager.nix                 REWRITTEN: imports shared-* + inline overrides
│   └── programs/
│       ├── nextcloud/default.nix        KEPT (fix hardcoded path)
│       ├── vesktop/default.nix          KEPT
│       └── smug/                        KEPT (has session YAML files)
│           ├── default.nix
│           └── smug/
│
├── lucak/                               NEW: work user
│   ├── nixos.nix                        NEW: user account
│   ├── home-manager.nix                 NEW: imports shared-* + shared-technative + overrides
│   └── programs/
│       └── aws/default.nix              MOVED from casper (fix hardcoded path)
│
└── antonia/
    ├── nixos.nix                        UNCHANGED
    ├── home-manager.nix                 SIMPLIFIED: imports shared-* + inline overrides
    └── programs/
        └── (empty or desktop only)
```

### Modules removed from casper/programs/

These become shared or are inlined via Inheritance Aspect:
- `git/` → `shared/git.nix` + inline override
- `zsh/` → `shared/zsh/` + inline override
- `firefox/` → `shared/firefox.nix` + inline override
- `fzf/` → `shared/fzf.nix`
- `zoxide/` → `shared/zoxide.nix`
- `autojump/` → `shared/autojump.nix`
- `atuin/` → `shared/atuin.nix`
- `jq/` → `shared/jq.nix`
- `tmux/` → `shared/tmux.nix`
- `tses/` → `shared/tses.nix`
- `font/` → `shared/font.nix`
- `age/` → `shared/age.nix`
- `neovim/` → `shared/neovim.nix`
- `opencode/` → `shared/opencode/`
- `dirty-repo-scanner/` → `shared/dirty-repo-scanner/`
- `aws/` → `lucak/programs/aws/`
- `rbw/` → removed (empty placeholder)
- `librewolf/` → inlined in casper home-manager.nix (disabled, simple)

### Modules removed from antonia/programs/

- `zsh/` → replaced by `shared/zsh/` + inline override (remove TN aliases)
- `neovim/` → replaced by `shared/neovim.nix`
- `firefox/` → replaced by `shared/firefox.nix` + inline override

### Affected host configurations

- `modules/hosts/gaming-casper/configuration.nix` — add `lucak` NixOS user + homeConfiguration
- `modules/hosts/personal-casper/configuration.nix` — add `lucak` NixOS user + homeConfiguration, remove `technative` import
- `modules/hosts/technative-casper/configuration.nix` — add `lucak` NixOS user + homeConfiguration, remove `technative` import

### Affected system modules

- `modules/programs/work/technative.nix` — reduced to only `security.acme` + `fonts.packages`

### Dendritic patterns used

| Pattern | Where | Purpose |
|---------|-------|---------|
| Simple Aspect | `shared-*` modules | Reusable base config for all users |
| Inheritance Aspect | `casper/home-manager.nix`, `lucak/home-manager.nix`, `antonia/home-manager.nix` | Import shared, override per-user values inline |
| Feature Closure | `lucak-aws`, `casper-nextcloud`, `casper-vesktop` | Self-contained complex features |

### Benefits

- **Mental separation**: Log out casper, log in lucak — clean work/personal switch
- **DRY**: 16 shared modules replace ~40 lines of duplicated config across users
- **System-wide cleanup**: ~50 work packages removed from system profile, only available to `lucak`
- **Scalable**: Adding a new user = `nixos.nix` + `home-manager.nix` with shared imports + overrides
- **Dendritic compliance**: Uses documented Inheritance Aspect and Simple Aspect patterns
- **Cleaner codebase**: ~16 inactive modules moved to `_unused/`

### Risks

- **Medium complexity**: Splitting modules and maintaining import correctness across 3 users and 3+ hosts
- **HM merge behavior**: Must verify that inline overrides merge correctly with shared module settings (NixOS module system handles this, but test thoroughly)
- **Path dependencies**: Secrets using relative paths (e.g., `../../../../../secrets/`) may break if files move
- **SSH key sharing**: Both `casper` and `lucak` use the same SSH key — this is intentional but means agenix secrets need to be accessible by both users

### Mitigation

- Test incrementally: shared modules first, then one user at a time
- Build all configurations before deploying (`nix build .#nixosConfigurations.<host>.config.system.build.toplevel`)
- Build HM configs standalone (`home-manager build --flake .#<user>@<host>`)
- Keep `_unused/` as reference for any missed configuration
- Test on non-critical host first (gaming-casper)
