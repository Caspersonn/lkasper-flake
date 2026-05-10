# Implementation Tasks: Multi-User Separation with Shared Home-Manager Modules

## 1. Preparation

- [x] 1.1 Create backup branch of current working configuration
- [x] 1.2 Verify current config builds: `nix build .#nixosConfigurations.gaming-casper.config.system.build.toplevel`
- [x] 1.3 Verify current HM builds: `home-manager build --flake .#casper@gaming-casper`

## 2. Create Shared Module Directory

- [x] 2.1 Create `modules/users/shared/` directory
- [x] 2.2 Create `modules/users/shared/zsh/` directory (has ohmyzsh-casper theme files)
- [x] 2.3 Create `modules/users/shared/opencode/` directory (has config/ dir)
- [x] 2.4 Create `modules/users/shared/dirty-repo-scanner/` directory (has config.yml)

## 3. Create Shared Single-File Modules (Simple Aspect)

Extract base config from `casper-*` modules, removing user-specific values.

- [x] 3.1 Create `modules/users/shared/git.nix` — `shared-git`
  - Source: `casper/programs/git/default.nix`
  - Extract: `programs.git.settings` (push, branch, pull, merge) + `programs.gh`
  - Remove: `user.email`, `user.name` (per-user override)
- [x] 3.2 Create `modules/users/shared/neovim.nix` — `shared-neovim`
  - Source: `casper/programs/neovim/default.nix` (identical to antonia-neovim)
  - Content: nixvim package + `EDITOR = "nvim"`
- [x] 3.3 Create `modules/users/shared/firefox.nix` — `shared-firefox`
  - Source: `casper/programs/firefox/default.nix`
  - Extract: `programs.firefox.enable`, `package`, shared extensions (uBlock, Bitwarden, Return YT Dislikes)
  - Remove: profiles (per-user), AWS/Granted extensions (lucak-only)
- [x] 3.4 Create `modules/users/shared/fzf.nix` — `shared-fzf`
  - Source: `casper/programs/fzf/default.nix`
  - Content: `programs.fzf = { enable = true; enableZshIntegration = true; }`
- [x] 3.5 Create `modules/users/shared/zoxide.nix` — `shared-zoxide`
  - Source: `casper/programs/zoxide/default.nix`
  - Content: `programs.zoxide = { enable = true; enableZshIntegration = true; }`
- [x] 3.6 Create `modules/users/shared/autojump.nix` — `shared-autojump`
  - Source: `casper/programs/autojump/default.nix`
  - Content: `programs.autojump.enable = true`
- [x] 3.7 Create `modules/users/shared/atuin.nix` — `shared-atuin`
  - Source: `casper/programs/atuin/default.nix`
  - Content: full atuin config (sync server, flags)
- [x] 3.8 Create `modules/users/shared/jq.nix` — `shared-jq`
  - Source: `casper/programs/jq/default.nix`
  - Content: `programs.jq.enable = true`
- [x] 3.9 Create `modules/users/shared/tmux.nix` — `shared-tmux`
  - Source: `casper/programs/tmux/default.nix`
  - Content: full tmux config (gruvbox, keybindings, plugins, tses integration)
- [x] 3.10 Create `modules/users/shared/tses.nix` — `shared-tses`
  - Source: `casper/programs/tses/default.nix`
  - Content: tmux sessionizer package
- [x] 3.11 Create `modules/users/shared/font.nix` — `shared-font`
  - Source: `casper/programs/font/default.nix`
  - Content: Nerd Fonts + fontconfig
- [x] 3.12 Create `modules/users/shared/age.nix` — `shared-age`
  - Source: `casper/programs/age/default.nix`
  - Content: agenix homeManagerModules import
- [x] 3.13 Create `modules/users/shared/technative.nix` — `shared-technative`
  - Source: `modules/programs/work/technative.nix` (environment.systemPackages section)
  - Convert: `environment.systemPackages` → `home.packages`
  - Verify: all flake inputs (jsonify-aws-dotfiles, bmc, race, ssmsh, aws-tui) are accessible in HM context

## 4. Create Shared Directory Modules

- [x] 4.1 Create `modules/users/shared/zsh/default.nix` — `shared-zsh`
  - Source: `casper/programs/zsh/default.nix`
  - Copy: `ohmyzsh-casper/` theme directory to `shared/zsh/ohmyzsh-casper/`
  - Extract: base zsh config (autosuggestion, syntax hl, oh-my-zsh, initExtra)
  - Remove: all shellAliases (per-user), `"aws"` and `"terraform"` from oh-my-zsh plugins
  - Fix: `ohmyzsh-casper` source path to reference local `./ohmyzsh-casper`
- [x] 4.2 Create `modules/users/shared/opencode/default.nix` — `shared-opencode`
  - Source: `casper/programs/opencode/default.nix`
  - Copy: `config/` directory to `shared/opencode/config/`
  - Fix: `/home/casper/git/personal/...` → `${config.home.homeDirectory}/git/personal/...`
- [x] 4.3 Create `modules/users/shared/dirty-repo-scanner/default.nix` — `shared-dirty-repo-scanner`
  - Source: `casper/programs/dirty-repo-scanner/default.nix`
  - Copy: `config.yml` to `shared/dirty-repo-scanner/config.yml`

## 5. Create lucak User

- [x] 5.1 Create `modules/users/lucak/` directory
- [x] 5.2 Create `modules/users/lucak/nixos.nix` — NixOS user account
  - Same groups as casper: networkmanager, wheel, docker, disk
  - Same SSH key as casper
  - Shell: zsh
- [x] 5.3 Create `modules/users/lucak/programs/` directory
- [x] 5.4 Move `casper/programs/aws/default.nix` → `lucak/programs/aws/default.nix` — `lucak-aws`
  - Fix: `builtins.path { path = /home/casper/.aws/... }` → dynamic path
  - Fix: relative secret paths if applicable
  - Test: `builtins.path` with `config.home.homeDirectory` (may need alternative approach)
- [x] 5.5 Create `modules/users/lucak/home-manager.nix` — `lucak` HM composition
  - Import: all shared modules + shared-technative + lucak-aws
  - Import: omarchy-nix lkh-* modules (same desktop)
  - Override: git identity, werk zsh aliases (tfplan, tfapply, aws-switch, bcd, bcdc)
  - Override: oh-my-zsh plugins (add "aws" + "terraform")
  - Override: Firefox work profile (Outlook, AWS extensions)
  - Add: AWS/Granted Firefox extensions

## 6. Rewrite casper/home-manager.nix (Inheritance Aspect)

- [x] 6.1 Rewrite `modules/users/casper/home-manager.nix`
  - Replace all `casper-*` imports with `shared-*` imports
  - Keep: `casper-nextcloud`, `casper-vesktop`, `casper-smug` imports
  - Add inline overrides: git identity, personal zsh aliases, personal Firefox profile
  - Add inline: librewolf config (disabled, simple)
  - Keep: omarchy-nix lkh-* imports
- [x] 6.2 Fix `casper/programs/nextcloud/default.nix`
  - Fix: `/home/casper/Documents` → `${config.home.homeDirectory}/Documents`
- [x] 6.3 Verify casper-vesktop needs no changes
- [x] 6.4 Verify casper-smug needs no changes

## 7. Simplify antonia/home-manager.nix (Inheritance Aspect)

- [x] 7.1 Rewrite `modules/users/antonia/home-manager.nix`
  - Replace: `antonia-zsh` → shared-zsh + inline override (NO TechNative aliases)
  - Replace: `antonia-neovim` → shared-neovim
  - Replace: `antonia-firefox` → shared-firefox + inline override (personal profile)
  - Keep: `antonia-git` identity inline, `gnome` desktop
  - Add: shared-fzf, shared-zoxide, shared-autojump, shared-atuin, shared-jq, shared-tmux, shared-tses, shared-font, shared-age

## 8. Update Host Configurations

- [x] 8.1 Update `modules/hosts/gaming-casper/configuration.nix`
  - Add: `"lucak@${hostname}"` to `flake.homeConfigurations`
  - Add: `lucak` to NixOS module imports (user account)
  - Keep: no `technative` import (gaming-casper doesn't have it)
- [x] 8.2 Update `modules/hosts/personal-casper/configuration.nix`
  - Add: `"lucak@${hostname}"` to `flake.homeConfigurations`
  - Add: `lucak` to NixOS module imports
  - Keep or remove: `technative` import (only if security.acme still needed)
- [x] 8.3 Update `modules/hosts/technative-casper/configuration.nix`
  - Add: `"lucak@${hostname}"` to `flake.homeConfigurations`
  - Add: `lucak` to NixOS module imports
  - Keep: `technative` import (security.acme needed for this host)

## 9. Minimize System-Wide technative.nix

- [x] 9.1 Edit `modules/programs/work/technative.nix`
  - Remove: entire `environment.systemPackages` block (moved to shared-technative)
  - Keep: `security.acme` config
  - Keep: `fonts.packages = [ lato ]`

## 10. Clean Up Inactive Modules

- [x] 10.1 Create `modules/_unused/` directory
- [x] 10.2 Move inactive casper Hyprland legacy modules
  - Move: `casper/desktop/hyprland/hyprland.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/hypridle.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/hyprlock/` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/avizo.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/swaync.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/walker.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/waybar/` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/eww/` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/script.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/vogix.nix` → `_unused/casper-hyprland-legacy/`
  - Move: `casper/desktop/hyprland/default.nix` → `_unused/casper-hyprland-legacy/`
- [x] 10.3 Move inactive casper themes
  - Move: `casper/themes/catppuccin/` → `_unused/casper-themes/catppuccin/`
  - Move: `casper/themes/gruvbox/` → `_unused/casper-themes/gruvbox/`
- [x] 10.4 Move inactive casper desktop/program modules
  - Move: `casper/desktop/gnome/` → `_unused/casper-gnome/`
  - Move: `casper/programs/kitty/` → `_unused/casper-kitty/`
  - Move: `casper/programs/ghostty/` → `_unused/casper-ghostty/`
- [x] 10.5 Move inactive antonia KDE module
  - Move: `antonia/desktop/kde/` → `_unused/antonia-kde/`

## 11. Remove Replaced casper Modules

After shared modules are created and casper/home-manager.nix is rewritten:

- [x] 11.1 Remove `casper/programs/git/` (replaced by shared-git + inline override)
- [x] 11.2 Remove `casper/programs/zsh/` (replaced by shared-zsh + inline override)
- [x] 11.3 Remove `casper/programs/firefox/` (replaced by shared-firefox + inline override)
- [x] 11.4 Remove `casper/programs/fzf/` (replaced by shared-fzf)
- [x] 11.5 Remove `casper/programs/zoxide/` (replaced by shared-zoxide)
- [x] 11.6 Remove `casper/programs/autojump/` (replaced by shared-autojump)
- [x] 11.7 Remove `casper/programs/atuin/` (replaced by shared-atuin)
- [x] 11.8 Remove `casper/programs/jq/` (replaced by shared-jq)
- [x] 11.9 Remove `casper/programs/tmux/` (replaced by shared-tmux)
- [x] 11.10 Remove `casper/programs/tses/` (replaced by shared-tses)
- [x] 11.11 Remove `casper/programs/font/` (replaced by shared-font)
- [x] 11.12 Remove `casper/programs/age/` (replaced by shared-age)
- [x] 11.13 Remove `casper/programs/neovim/` (replaced by shared-neovim)
- [x] 11.14 Remove `casper/programs/opencode/` (replaced by shared-opencode)
- [x] 11.15 Remove `casper/programs/dirty-repo-scanner/` (replaced by shared-dirty-repo-scanner)
- [x] 11.16 Remove `casper/programs/aws/` (moved to lucak-aws)
- [x] 11.17 Remove `casper/programs/rbw/` (empty placeholder)
- [x] 11.18 Remove `casper/programs/librewolf/` (inlined in casper home-manager.nix)

## 12. Remove Replaced antonia Modules

- [x] 12.1 Remove `antonia/programs/zsh/` (replaced by shared-zsh + inline override)
  - Also remove: `antonia/programs/zsh/ohmyzsh-casper/` (duplicated, now in shared)
- [x] 12.2 Remove `antonia/programs/neovim/` (replaced by shared-neovim)
- [x] 12.3 Remove `antonia/programs/firefox/` (replaced by shared-firefox + inline override)
- [x] 12.4 Remove `antonia/programs/git/` (replaced by shared-git + inline override)

## 13. Build & Test — Phase 1: Shared Modules + casper

- [ ] 13.1 Build casper NixOS config: `nix build .#nixosConfigurations.gaming-casper.config.system.build.toplevel`
- [ ] 13.2 Build casper HM config: `home-manager build --flake .#casper@gaming-casper`
- [ ] 13.3 Verify flake outputs: `nix flake show` (check homeConfigurations)
- [ ] 13.4 Fix any module merge issues (especially zsh plugins, firefox extensions)

## 14. Build & Test — Phase 2: lucak User

- [ ] 14.1 Build lucak HM config: `home-manager build --flake .#lucak@gaming-casper`
- [ ] 14.2 Verify lucak-aws module builds (builtins.path fix)
- [ ] 14.3 Verify shared-technative packages are in lucak's profile
- [ ] 14.4 Verify technative packages are NOT in casper's profile

## 15. Build & Test — Phase 3: antonia + All Hosts

- [ ] 15.1 Build antonia configs (if applicable host exists)
- [ ] 15.2 Build all host NixOS configs:
  - `nix build .#nixosConfigurations.gaming-casper.config.system.build.toplevel`
  - `nix build .#nixosConfigurations.personal-casper.config.system.build.toplevel`
  - `nix build .#nixosConfigurations.technative-casper.config.system.build.toplevel`
- [ ] 15.3 Build all homeConfigurations:
  - `home-manager build --flake .#casper@gaming-casper`
  - `home-manager build --flake .#lucak@gaming-casper`
  - `home-manager build --flake .#casper@personal-casper`
  - `home-manager build --flake .#lucak@personal-casper`
  - `home-manager build --flake .#casper@technative-casper`
  - `home-manager build --flake .#lucak@technative-casper`

## 16. Deploy & Validate

- [ ] 16.1 Deploy to gaming-casper first (least critical)
  - `sudo nixos-rebuild switch --flake .#gaming-casper`
  - Log in as casper — verify shell, git, firefox, neovim work
  - Log out, log in as lucak — verify shell, AWS tools, work packages, firefox work profile
- [ ] 16.2 Deploy to personal-casper
  - Same validation as above
- [ ] 16.3 Deploy to technative-casper
  - Same validation + verify security.acme still works
- [ ] 16.4 Verify antonia user on applicable hosts

## 17. Post-Deploy Cleanup

- [x] 17.1 Remove empty directories left after module moves
- [ ] 17.2 Verify `modules/_unused/` is ignored by import-tree
- [ ] 17.3 Update `openspec/config.yaml` context section (add lucak user, update module counts)

**IMPORTANT**: Tasks 11-12 (removing old modules) should only happen AFTER tasks 13-14 confirm the new shared modules work. Do not delete originals before the new setup builds successfully.
