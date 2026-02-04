# Implementation Tasks: Home-Manager Dendritic Migration

## 1. Preparation & Setup
- [ ] 1.1 Review dendritic pattern documentation for home-manager modules
- [ ] 1.2 Study mipnix user module structure (https://github.com/mipmip/mipnix/tree/main/modules/users/pim)
- [ ] 1.3 Study mipnix host integration (https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/configuration.nix)
- [ ] 1.4 Create backup branch of current working configuration
- [ ] 1.5 Document current home-manager module inventory (~54 files)
- [ ] 1.6 Plan feature mapping (home/* → modules/users/casper/casper-*.nix)

## 2. Create User Module Structure
- [ ] 2.1 Create `modules/users/casper/` directory (if not exists)
- [ ] 2.2 Create `modules/users/casper/home-manager.nix` (main composition file)
  - [ ] 2.2.1 Add `{ inputs, self, ... }:` wrapper
  - [ ] 2.2.2 Define `flake.modules.homeManager.casper`
  - [ ] 2.2.3 Add `imports = with inputs.self.modules.homeManager; []` skeleton
  - [ ] 2.2.4 Add `nixpkgs.config.allowUnfree = true;`
  - [ ] 2.2.5 Reference: https://github.com/mipmip/mipnix/blob/main/modules/users/pim/home-manager.nix
- [ ] 2.3 Create subdirectory structure:
  - [ ] 2.3.1 `modules/users/casper/desktop/`
  - [ ] 2.3.2 `modules/users/casper/programs/`
  - [ ] 2.3.3 `modules/users/casper/themes/`

## 3. Migrate Shell Programs (Simple Aspect)
- [ ] 3.1 Migrate ZSH to `modules/users/casper/programs/zsh/default.nix`
  - [ ] 3.1.1 Create directory `modules/users/casper/programs/zsh/`
  - [ ] 3.1.2 Create default.nix with `{ inputs, ... }:` wrapper
  - [ ] 3.1.3 Expose `flake.modules.homeManager.casper-zsh`
  - [ ] 3.1.4 Direct HM config: `programs.zsh = { enable = true; ... };`
  - [ ] 3.1.5 Migrate all config from home/programs/zsh/
  - [ ] 3.1.6 Add to home-manager.nix imports
- [ ] 3.2 Migrate tmux to `modules/users/casper/programs/tmux/default.nix`
  - [ ] 3.2.1 Create directory `modules/users/casper/programs/tmux/`
  - [ ] 3.2.2 Create default.nix exposing `casper-tmux`
  - [ ] 3.2.3 Migrate config files from home/programs/tmux/
  - [ ] 3.2.4 Add to home-manager.nix imports
- [ ] 3.3 Migrate atuin to `modules/users/casper/programs/atuin/default.nix`
  - [ ] 3.3.1 Create directory `modules/users/casper/programs/atuin/`
  - [ ] 3.3.2 Expose `flake.modules.homeManager.casper-atuin`
  - [ ] 3.3.3 Migrate from home/programs/atuin.nix
  - [ ] 3.3.4 Add to home-manager.nix imports
- [ ] 3.4 Migrate fzf to `modules/users/casper/programs/fzf/default.nix`
  - [ ] 3.4.1 Create directory `modules/users/casper/programs/fzf/`
  - [ ] 3.4.2 Expose `flake.modules.homeManager.casper-fzf`
  - [ ] 3.4.3 Migrate from home/programs/fzf.nix
  - [ ] 3.4.4 Add to home-manager.nix imports
- [ ] 3.5 Migrate zoxide to `modules/users/casper/programs/zoxide/default.nix`
  - [ ] 3.5.1 Create directory `modules/users/casper/programs/zoxide/`
  - [ ] 3.5.2 Expose `flake.modules.homeManager.casper-zoxide`
  - [ ] 3.5.3 Migrate from home/programs/zoxide.nix
  - [ ] 3.5.4 Add to home-manager.nix imports
- [ ] 3.6 Migrate autojump to `modules/users/casper/programs/autojump/default.nix`
  - [ ] 3.6.1 Create directory `modules/users/casper/programs/autojump/`
  - [ ] 3.6.2 Expose `flake.modules.homeManager.casper-autojump`
  - [ ] 3.6.3 Migrate from home/programs/autojump.nix
  - [ ] 3.6.4 Add to home-manager.nix imports

## 4. Migrate Development Tools (Simple Aspect)
- [ ] 4.1 Migrate git to `modules/users/casper/programs/git/default.nix`
  - [ ] 4.1.1 Create directory `modules/users/casper/programs/git/`
  - [ ] 4.1.2 Expose `flake.modules.homeManager.casper-git`
  - [ ] 4.1.3 Migrate from home/programs/git.nix
  - [ ] 4.1.4 Add to home-manager.nix imports
- [ ] 4.2 Migrate neovim to `modules/users/casper/programs/neovim/default.nix`
  - [ ] 4.2.1 Create directory `modules/users/casper/programs/neovim/`
  - [ ] 4.2.2 Create default.nix exposing `casper-neovim`
  - [ ] 4.2.3 Migrate from home/programs/neovim/
  - [ ] 4.2.4 Add to home-manager.nix imports
- [ ] 4.3 Skip nvim-old if deprecated

## 5. Migrate Desktop Environments (Simple Aspect)
- [ ] 5.1 Migrate Hyprland HM config to `modules/users/casper/desktop/hyprland/default.nix`
  - [ ] 5.1.1 Create directory `modules/users/casper/desktop/hyprland/`
  - [ ] 5.1.2 Create default.nix exposing `casper-hyprland`
  - [ ] 5.1.3 Direct config: `wayland.windowManager.hyprland = { ... };`
  - [ ] 5.1.4 Migrate from home/desktop-environments/hyprland/
  - [ ] 5.1.5 Include waybar, hypridle, hyprlock, walker, etc.
  - [ ] 5.1.6 Preserve subdirectory structure for waybar/ if needed
  - [ ] 5.1.7 Add to home-manager.nix imports
- [ ] 5.2 Migrate GNOME HM config to `modules/users/casper/desktop/gnome/default.nix`
  - [ ] 5.2.1 Create directory `modules/users/casper/desktop/gnome/`
  - [ ] 5.2.2 Create default.nix exposing `casper-gnome`
  - [ ] 5.2.3 Migrate from home/desktop-environments/gnome/
  - [ ] 5.2.4 Add to home-manager.nix imports (commented - conditional per host)
- [ ] 5.3 Skip hyprland.bak if deprecated

## 6. Migrate Terminal Emulators (Simple Aspect)
- [ ] 6.1 Migrate kitty to `modules/users/casper/programs/kitty/default.nix`
  - [ ] 6.1.1 Create directory `modules/users/casper/programs/kitty/`
  - [ ] 6.1.2 Expose `flake.modules.homeManager.casper-kitty`
  - [ ] 6.1.3 Migrate from home/programs/kitty.nix
  - [ ] 6.1.4 Add to home-manager.nix imports
- [ ] 6.2 Migrate ghostty to `modules/users/casper/programs/ghostty/default.nix`
  - [ ] 6.2.1 Create directory `modules/users/casper/programs/ghostty/`
  - [ ] 6.2.2 Expose `flake.modules.homeManager.casper-ghostty`
  - [ ] 6.2.3 Migrate from home/programs/ghostty.nix
  - [ ] 6.2.4 Add to home-manager.nix imports

## 7. Migrate Browsers (Simple Aspect)
- [ ] 7.1 Migrate Firefox to `modules/users/casper/programs/firefox/default.nix`
  - [ ] 7.1.1 Create directory `modules/users/casper/programs/firefox/`
  - [ ] 7.1.2 Expose `flake.modules.homeManager.casper-firefox`
  - [ ] 7.1.3 Migrate from home/programs/firefox.nix
  - [ ] 7.1.4 Add to home-manager.nix imports
- [ ] 7.2 Migrate LibreWolf to `modules/users/casper/programs/librewolf/default.nix`
  - [ ] 7.2.1 Create directory `modules/users/casper/programs/librewolf/`
  - [ ] 7.2.2 Expose `flake.modules.homeManager.casper-librewolf`
  - [ ] 7.2.3 Migrate from home/programs/librewolf.nix
  - [ ] 7.2.4 Add to home-manager.nix imports

## 8. Migrate Media Applications (Simple Aspect)
- [ ] 8.1 Migrate Vesktop to `modules/users/casper/programs/vesktop/default.nix`
  - [ ] 8.1.1 Create directory `modules/users/casper/programs/vesktop/`
  - [ ] 8.1.2 Expose `flake.modules.homeManager.casper-vesktop`
  - [ ] 8.1.3 Migrate from home/programs/vesktop.nix
  - [ ] 8.1.4 Add to home-manager.nix imports
- [ ] 8.2 Migrate RetroArch to `modules/users/casper/programs/retroarch/default.nix`
  - [ ] 8.2.1 Create directory `modules/users/casper/programs/retroarch/`
  - [ ] 8.2.2 Expose `flake.modules.homeManager.casper-retroarch`
  - [ ] 8.2.3 Migrate from home/programs/retroarch/
  - [ ] 8.2.4 Add to home-manager.nix imports

## 9. Migrate Utility Programs (Simple Aspect)
- [ ] 9.1 Migrate dirtygit to `modules/users/casper/programs/dirtygit/default.nix`
  - [ ] 9.1.1 Create directory `modules/users/casper/programs/dirtygit/`
  - [ ] 9.1.2 Expose `flake.modules.homeManager.casper-dirtygit`
  - [ ] 9.1.3 Migrate from home/programs/dirtygit/
  - [ ] 9.1.4 Add to home-manager.nix imports
- [ ] 9.2 Migrate rbw to `modules/users/casper/programs/rbw/default.nix`
  - [ ] 9.2.1 Create directory `modules/users/casper/programs/rbw/`
  - [ ] 9.2.2 Expose `flake.modules.homeManager.casper-rbw`
  - [ ] 9.2.3 Migrate from home/programs/rbw/
  - [ ] 9.2.4 Add to home-manager.nix imports
- [ ] 9.3 Migrate smug to `modules/users/casper/programs/smug/default.nix`
  - [ ] 9.3.1 Create directory `modules/users/casper/programs/smug/`
  - [ ] 9.3.2 Expose `flake.modules.homeManager.casper-smug`
  - [ ] 9.3.3 Migrate from home/programs/smug/
  - [ ] 9.3.4 Add to home-manager.nix imports
- [ ] 9.4 Migrate opencode to `modules/users/casper/programs/opencode/default.nix`
  - [ ] 9.4.1 Create directory `modules/users/casper/programs/opencode/`
  - [ ] 9.4.2 Expose `flake.modules.homeManager.casper-opencode`
  - [ ] 9.4.3 Migrate from home/programs/opencode.nix
  - [ ] 9.4.4 Add to home-manager.nix imports
- [ ] 9.5 Migrate jq to `modules/users/casper/programs/jq/default.nix`
  - [ ] 9.5.1 Create directory `modules/users/casper/programs/jq/`
  - [ ] 9.5.2 Expose `flake.modules.homeManager.casper-jq`
  - [ ] 9.5.3 Migrate from home/programs/jq.nix
  - [ ] 9.5.4 Add to home-manager.nix imports
- [ ] 9.6 Migrate font config to `modules/users/casper/programs/font/default.nix`
  - [ ] 9.6.1 Create directory `modules/users/casper/programs/font/`
  - [ ] 9.6.2 Expose `flake.modules.homeManager.casper-font`
  - [ ] 9.6.3 Migrate from home/programs/font.nix
  - [ ] 9.6.4 Add to home-manager.nix imports
- [ ] 9.7 Migrate AWS config to `modules/users/casper/programs/aws/default.nix`
  - [ ] 9.7.1 Create directory `modules/users/casper/programs/aws/`
  - [ ] 9.7.2 Expose `flake.modules.homeManager.casper-aws`
  - [ ] 9.7.3 Migrate from home/programs/aws/
  - [ ] 9.7.4 Add to home-manager.nix imports

## 10. Migrate Themes (Simple Aspect)
- [ ] 10.1 Migrate Gruvbox theme to `modules/users/casper/themes/gruvbox/default.nix`
  - [ ] 10.1.1 Create directory `modules/users/casper/themes/gruvbox/`
  - [ ] 10.1.2 Expose `flake.modules.homeManager.casper-gruvbox`
  - [ ] 10.1.3 Migrate from home/themes/Gruvbox/
  - [ ] 10.1.4 Add to home-manager.nix imports
- [ ] 10.2 Migrate Catppuccin theme to `modules/users/casper/themes/catppuccin/default.nix`
  - [ ] 10.2.1 Create directory `modules/users/casper/themes/catppuccin/`
  - [ ] 10.2.2 Expose `flake.modules.homeManager.casper-catppuccin`
  - [ ] 10.2.3 Migrate from home/themes/Catppuccin/
  - [ ] 10.2.4 Add to home-manager.nix imports (commented - alternative to gruvbox)

## 11. Verify Import-Tree Discovery
- [ ] 11.1 Ensure all HM feature files have `{ inputs, ... }:` or `{ inputs, self, ... }:` wrapper
- [ ] 11.2 Ensure all files are git-tracked (import-tree requirement)
- [ ] 11.3 Test feature discovery: `nix eval .#modules.homeManager --apply builtins.attrNames`
- [ ] 11.4 Verify expected features are listed (casper-zsh, casper-git, casper, etc.)

## 12. Create/Update makeHomeConf Helper
- [ ] 12.1 Check if `self.lib.makeHomeConf` exists in `modules/nix/lib/flake-parts.nix`
- [ ] 12.2 If not, create helper function:
  - [ ] 12.2.1 Accept parameters: hostname, system, imports
  - [ ] 12.2.2 Return home-manager.lib.homeManagerConfiguration
  - [ ] 12.2.3 Integrate home-manager input
- [ ] 12.3 Reference mipnix lib structure for guidance

## 13. Integrate Home-Manager in Each Host
- [ ] 13.1 Update `modules/hosts/technative-casper/configuration.nix`
  - [ ] 13.1.1 Add `flake.homeConfigurations."casper@technative-casper"`
  - [ ] 13.1.2 Use `self.lib.makeHomeConf { hostname = "technative-casper"; ... }`
  - [ ] 13.1.3 Import `inputs.self.modules.homeManager.casper`
  - [ ] 13.1.4 Reference: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/configuration.nix
- [ ] 13.2 Update `modules/hosts/gaming-casper/configuration.nix`
  - [ ] 13.2.1 Add `flake.homeConfigurations."casper@gaming-casper"`
  - [ ] 13.2.2 Use makeHomeConf helper
  - [ ] 13.2.3 Import user's home-manager module
- [ ] 13.3 Update `modules/hosts/personal-casper/configuration.nix`
  - [ ] 13.3.1 Add `flake.homeConfigurations."casper@personal-casper"`
  - [ ] 13.3.2 Use makeHomeConf helper
  - [ ] 13.3.3 Import user's home-manager module
- [ ] 13.4 Update `modules/hosts/server-casper/configuration.nix`
  - [ ] 13.4.1 Add `flake.homeConfigurations."casper@server-casper"` (if HM used on server)
  - [ ] 13.4.2 Use makeHomeConf helper
  - [ ] 13.4.3 Import user's home-manager module

## 14. Testing & Validation
- [ ] 14.1 Build all host configurations
  - [ ] 14.1.1 `nixos-rebuild build --flake .#technative-casper`
  - [ ] 14.1.2 `nixos-rebuild build --flake .#gaming-casper`
  - [ ] 14.1.3 `nixos-rebuild build --flake .#personal-casper`
  - [ ] 14.1.4 `nixos-rebuild build --flake .#server-casper`
- [ ] 14.2 Build home-manager configurations
  - [ ] 14.2.1 `home-manager build --flake .#casper@technative-casper`
  - [ ] 14.2.2 `home-manager build --flake .#casper@gaming-casper`
  - [ ] 14.2.3 `home-manager build --flake .#casper@personal-casper`
  - [ ] 14.2.4 `home-manager build --flake .#casper@server-casper` (if applicable)
- [ ] 14.3 Verify flake outputs: `nix flake show`
  - [ ] 14.3.1 Check nixosConfigurations exist
  - [ ] 14.3.2 Check homeConfigurations exist
- [ ] 14.4 Test home-manager activation on a test host
  - [ ] 14.4.1 Verify HM features are activated
  - [ ] 14.4.2 Check for any path or config errors
  - [ ] 14.4.3 Test shell programs (zsh, tmux work correctly)
  - [ ] 14.4.4 Test desktop environment (Hyprland/GNOME launches)
  - [ ] 14.4.5 Test applications (browsers, dev tools work)

## 15. Documentation
- [ ] 15.1 Update `modules/README.md` with HM pattern info
  - [ ] 15.1.1 Document user HM feature structure (flat files)
  - [ ] 15.1.2 Explain naming convention (casper-* prefix)
  - [ ] 15.1.3 Show example HM feature module
  - [ ] 15.1.4 Show home-manager.nix composition pattern
  - [ ] 15.1.5 Show host integration pattern
- [ ] 15.2 Document user module pattern
  - [ ] 15.2.1 How to add new HM features
  - [ ] 15.2.2 How to customize per-user settings
  - [ ] 15.2.3 How to add additional users
- [ ] 15.3 Create guide for HM feature migration
  - [ ] 15.3.1 Steps to migrate a program config
  - [ ] 15.3.2 When to use flat file vs subdirectory
  - [ ] 15.3.3 How to test HM features
- [ ] 15.4 Update main README.md with HM structure overview
- [ ] 15.5 Document that per-host HM integration replaced centralized parts/home-manager.nix

## 16. Cleanup
- [ ] 16.1 Verify all home/ content migrated
  - [ ] 16.1.1 Check home/desktop-environments/ fully migrated
  - [ ] 16.1.2 Check home/programs/ fully migrated
  - [ ] 16.1.3 Check home/themes/ fully migrated
  - [ ] 16.1.4 Verify home/default.nix no longer needed
- [ ] 16.2 Delete `parts/home-manager.nix` (AFTER USER CONFIRMS):
  - [ ] 16.2.1 `rm parts/home-manager.nix`
  - [ ] 16.2.2 Centralized approach no longer needed
- [ ] 16.3 Rename home/ directory for backup (AFTER USER CONFIRMS):
  - [ ] 16.3.1 `mv home _oldhome`
  - [ ] 16.3.2 Update .gitignore: `echo "_old*/" >> .gitignore`
- [ ] 16.4 Document that _oldhome/ can be removed after production verification
- [ ] 16.5 Create migration completion checklist

**IMPORTANT**: Wait for user to test and confirm migration success before cleanup

## 17. Post-Migration Validation
- [ ] 17.1 User validates functionality on production systems
  - [ ] 17.1.1 Test on technative-casper
  - [ ] 17.1.2 Test on gaming-casper
  - [ ] 17.1.3 Test on personal-casper
  - [ ] 17.1.4 Test on server-casper (if HM used)
- [ ] 17.2 Document any adjustments needed
- [ ] 17.3 Finalize migration when user confirms success

## 18. Future Enhancements (Optional Notes)
- [ ] 18.1 Note: Multi-user support ready (can add additional user directories)
- [ ] 18.2 Note: Desktop environment selection can be made conditional per host
- [ ] 18.3 Document potential next steps:
  - [ ] 18.3.1 Add additional user profiles (alice/, bob/)
  - [ ] 18.3.2 Enhance theme system with Stylix
  - [ ] 18.3.3 Extract reusable HM features to generic modules
  - [ ] 18.3.4 Create per-host HM feature variations if needed
