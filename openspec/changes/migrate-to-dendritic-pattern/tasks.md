## 1. Preparation & Setup
- [x] 1.1 Review dendritic pattern documentation thoroughly (all 8 aspect patterns)
- [x] 1.2 Study Doc-Steve's example repository structure
- [x] 1.3 Create backup branch of current working configuration
- [x] 1.4 Document current NixOS module inventory
- [x] 1.5 Plan feature mapping (current modules → dendritic features)

## 2. Migrate parts/ to modules/nix/flake-parts/
- [x] 2.1 Note: flake-parts already in use (see flake.nix and parts/)
- [x] 2.2 Create `modules/nix/flake-parts/` directory
- [x] 2.3 Migrate `parts/systems.nix` → `modules/nix/systems/flake-parts.nix`
  - [x] 2.3.1 Keep systems definition as-is (x86_64-linux, aarch64-linux)
- [x] 2.4 Migrate `parts/formatter.nix` → `modules/nix/formatter/flake-parts.nix`
  - [x] 2.4.1 Keep formatter definition as-is (nixfmt-classic)
- [x] 2.5 Migrate `parts/overlays.nix` → `modules/nix/lib/flake-parts.nix`
  - [x] 2.5.1 Extract importFromChannelForSystem helper function
  - [x] 2.5.2 Create flake.lib option structure
  - [x] 2.5.3 Add makeNixos helper for host feature usage
- [x] 2.6 Remove `parts/nixos.nix` (replaced by self-contained host features)
  - [x] 2.6.1 Note: makeNixosConf pattern replaced by dendritic host features
- [ ] 2.7 Keep `parts/home-manager.nix` (Home-Manager not migrated yet)
  - [ ] 2.7.1 Note: makeHomeConf pattern may be kept or adapted
- [x] 2.8 Add vic/import-tree to flake inputs
- [x] 2.9 Enable flake-parts.flakeModules.modules in flake.nix
- [x] 2.10 Update `flake.nix` to use import-tree for automatic discovery
- [ ] 2.11 Create `modules/nix/flake-parts/factory.nix` (factory option definition) - OPTIONAL
- [ ] 2.12 Rename `parts/` to `_oldparts/` directory (after user confirms migration success)

## 3. Directory Structure Creation
- [x] 3.1 Create `modules/nix/` directory
- [x] 3.2 Create `modules/system/` directory
- [x] 3.3 Create `modules/system/settings/` directory
- [ ] 3.4 Create `modules/system/system types/` directory - SKIPPED (not needed for current setup)
- [x] 3.5 Create `modules/programs/` directory
- [x] 3.6 Create `modules/services/` directory
- [x] 3.7 Create `modules/factory/` directory
- [x] 3.8 Create `modules/hosts/` directory
- [x] 3.9 Create `modules/users/` directory
- [x] 3.10 Document directory naming convention ([N], [D], [ND], [nd], etc.)

## 4. Constants Aspect Implementation
- [x] 4.1 Create `modules/system/settings/systemConstants/` directory
- [x] 4.2 Create `flake-parts.nix` exposing systemConstants as flake.modules.nixos
- [x] 4.3 Define systemConstants option (user, programs, ui, system)
- [x] 4.4 Set default constants (user info, program choices, admin email)

## 5. System Type Features (Inheritance Aspect)
- [ ] 5.1 SKIPPED - Not needed for current host-based composition
- [ ] 5.2 SKIPPED - Hosts directly import features they need
- [ ] 5.3 SKIPPED - Desktop features imported directly by hosts

## 6. System Settings Features (Simple Aspect)
- [ ] 6.1 OPTIONAL - Bluetooth settings can be in host configs
- [ ] 6.2 OPTIONAL - Boot settings in host hardware.nix
- [ ] 6.3 OPTIONAL - Firmware settings in host hardware.nix  
- [ ] 6.4 OPTIONAL - Network settings in host configs

## 7. Service Features (Simple Aspect)
- [x] 7.1 Migrate Docker to `modules/services/docker [N]/docker.nix`
  - [x] 7.1.1 Create file exposing `flake.modules.nixos.docker`
  - [x] 7.1.2 Direct configuration: `virtualisation.docker.enable = true;`
  - [x] 7.1.3 Integrate secrets using agenix if needed
- [x] 7.2 Migrate Tailscale to `modules/services/tailscale [N]/tailscale.nix`
  - [x] 7.2.1 Direct configuration: `services.tailscale = { enable = true; ... };`
- [x] 7.3 Migrate OpenVPN to `modules/services/openvpn [N]/openvpn.nix`
- [x] 7.4 Migrate Syncthing to `modules/services/syncthing [N]/syncthing.nix` (both client and server)
  - [x] 7.4.1 Create direct syncthing configuration
  - [x] 7.4.2 Prepare for Collector Aspect (device IDs from hosts) if needed
- [x] 7.5 Migrate SMB service to `modules/services/smb [N]/smb.nix`
- [x] 7.6 Migrate Atuin service to `modules/services/atuin [N]/atuin.nix`
- [x] 7.7 Migrate Coolerd to `modules/services/coolerd [N]/coolerd.nix`
- [x] 7.8 Migrate Croctalk to `modules/services/croctalk [N]/croctalk.nix`
- [x] 7.9 Migrate Birthday service to `modules/services/birthday [N]/birthday.nix`
- [x] 7.10 Migrate Bluetooth receiver to `modules/services/bluetooth-receiver [N]/bluetooth-receiver.nix`
- [x] 7.11 Migrate MySQL service to `modules/services/mysql [N]/mysql.nix`
- [x] 7.12 Migrate additional services (23 total services migrated)

**Note**: Services use Simple Aspect - direct NixOS configuration, no `mkEnableOption` or `mkIf` wrappers

## 8. Program Features (Multi-Context & Conditional Aspects)
- [x] 8.1 Migrate Hyprland to `modules/programs/desktop/hyprland [N]/hyprland.nix`
  - [x] 8.1.1 Direct configuration: `programs.hyprland.enable = true;`
  - [x] 8.1.2 Include system packages and settings
  - [x] 8.1.3 Multi-Context: system config + optional HM aspects
- [x] 8.2 Migrate CLI tools to `modules/programs/cli/tools [N]/tools.nix`
  - [x] 8.2.1 Direct package list: `environment.systemPackages = [...]`
- [x] 8.3 Migrate GNOME to `modules/programs/desktop/gnome [N]/gnome.nix`
  - [x] 8.3.1 Direct configuration: `services.xserver.desktopManager.gnome.enable = true;`
  - [x] 8.3.2 Include GNOME-specific packages
- [x] 8.4 Migrate KDE to `modules/programs/desktop/kde [N]/kde.nix`
- [x] 8.5 Migrate Cosmic to `modules/programs/desktop/cosmic [N]/cosmic.nix`
- [x] 8.6 Migrate development tools to `modules/programs/dev/` (git, languages, lsp)
- [x] 8.7 Migrate gaming programs to `modules/programs/gaming/` (gaming, steam, retroarch)

**Note**: Programs use direct configuration, Multi-Context means they configure both system and HM aspects in one module

## 9. Package Collection Features (Simple Aspect)
- [x] 9.1 Migrate CLI tools to `modules/programs/cli/tools [N]/tools.nix`
  - [x] 9.1.1 Direct package list: `environment.systemPackages = with pkgs; [...]`
- [x] 9.2 Migrate GUI packages to `modules/programs/gui/apps [N]/apps.nix`
- [x] 9.3 Migrate gaming packages to `modules/programs/gaming/gaming [N]/gaming.nix`
  - [x] 9.3.1 Include steam, retroarch, etc.
- [x] 9.4 Migrate work packages to `modules/programs/work/technative [N]/technative.nix`
  - [x] 9.4.1 TechNative-specific tools (bmc, race, etc.)
- [x] 9.5 Migrate server packages to `modules/programs/server/tools [N]/tools.nix`
- [x] 9.6 Handle special packages:
  - [x] 9.6.1 Chromium → `modules/programs/gui/chromium [N]/chromium.nix`
  - [x] 9.6.2 Spotify → `modules/programs/gui/spotify [N]/spotify.nix`
  - [x] 9.6.3 Bambu Labs → `modules/programs/gui/bambu-labs [N]/bambu-labs.nix`
  - [x] 9.6.4 Rapid7 → `modules/programs/system/rapid7 [N]/rapid7.nix`
  - [x] 9.6.5 nix-ld → `modules/programs/system/nix-ld [N]/nix-ld.nix`
  - [x] 9.6.6 Additional system tools (hardware-utils, disk-utils, fonts)
- [x] 9.7 Apply Conditional Aspect for platform-specific packages where needed

**Note**: Package modules are Simple Aspect - just list packages in `environment.systemPackages`

## 10. Factory Aspects
- [ ] 10.1 OPTIONAL - User factory not needed for current setup
- [ ] 10.2 OPTIONAL - Mount factory not needed for current setup
- [ ] 10.3 OPTIONAL - Can be added later if needed
- [ ] 10.4 Factory directory created but not populated

## 11. User Features
- [ ] 11.1 OPTIONAL - User modules not needed for current setup (using direct host configs)
- [ ] 11.2 Users directory created but not populated
- [ ] 11.3 Can be added later if user-specific customizations needed
  - [ ] 11.1.2 Use Factory Aspect to generate base user config
  - [ ] 11.1.3 Define NixOS aspect (system user settings)
  - [ ] 11.1.4 Define homeManager aspect (home config)
  - [ ] 11.1.5 Import program features that user wants
  - [ ] 11.1.6 Add user-specific customizations
- [ ] 11.2 Keep existing home/ directory structure for now
- [ ] 11.3 Link home-manager configs through user feature

- [ ] 13.5 Update `parts/home-manager.nix` for user features integration
  - [ ] 13.5.1 Consider if makeHomeConf still needed or if user features handle it
  - [ ] 13.5.2 Update to work with user features from modules/users/
- [ ] 13.6 Verify flake outputs: `nix flake show`

## 14. Collector Aspect Implementation
- [ ] 14.1 Identify all uses of Collector Aspect:
  - [ ] 14.1.1 Syncthing device IDs
  - [ ] 14.1.2 Any other host-contributed data
- [ ] 14.2 Implement syncthing device collection
  - [ ] 14.2.1 Each host contributes its device ID to syncthing feature
- [ ] 14.3 Document Collector Aspect usage

## 15. DRY Aspect Implementation (if needed)
- [ ] 15.1 Identify repeated attribute patterns
  - [ ] 15.1.1 Network interface configurations
  - [ ] 15.1.2 Any other reusable attribute sets
- [ ] 15.2 Create DRY aspect modules if needed
  - [ ] 15.2.1 Define custom module class (e.g., networkInterface)
  - [ ] 15.2.2 Create reusable attribute components
- [ ] 15.3 Use DRY aspects with lib.mkMerge
- [ ] 15.4 Document DRY Aspect usage

## 16. Testing & Validation
**Note**: Testing will be performed by the user after each phase. Implementation focuses on code migration only.

- [ ] 16.1 Build all hosts configuration available for testing
- [ ] 16.2 Document any known issues or required manual steps

## 17. Documentation
- [ ] 17.1 Create `modules/README.md` explaining dendritic structure
  - [ ] 17.1.1 Directory naming conventions
  - [ ] 17.1.2 When to use each aspect pattern
  - [ ] 17.1.3 Feature vs user customization guidelines
- [ ] 17.2 Document each aspect pattern with examples:
  - [ ] 17.2.1 Simple Aspect
  - [ ] 17.2.2 Multi-Context Aspect
  - [ ] 17.2.3 Inheritance Aspect
  - [ ] 17.2.4 Conditional Aspect
  - [ ] 17.2.5 Collector Aspect
  - [ ] 17.2.6 Constants Aspect
  - [ ] 17.2.7 DRY Aspect
  - [ ] 17.2.8 Factory Aspect
- [ ] 17.3 Create guide for adding new features
  - [ ] 17.3.1 Choose appropriate aspect pattern
  - [ ] 17.3.2 Determine correct directory location
  - [ ] 17.3.3 Apply naming conventions
- [ ] 17.4 Document helper functions in lib/
- [ ] 17.5 Document factory functions
- [ ] 17.6 Update main README.md with new structure overview
- [ ] 17.7 Create troubleshooting guide:
  - [ ] 17.7.1 Common import issues
  - [ ] 17.7.2 Flake.nix regeneration (flake-file)
  - [ ] 17.7.3 Module class conflicts
- [ ] 17.8 Add architecture diagram showing feature composition









## 19. Post-Migration Validation
**Note**: User will validate functionality. Implementation provides working structure.

- [ ] 19.1 Ensure all features use proper flake-parts module structure
- [ ] 19.2 Document migration completion checklist

## 20. Future Preparation (Optional Notes)
- [ ] 20.1 Note: Darwin aspects prepared but not implemented
- [ ] 20.2 Note: Home-Manager migration can be separate follow-up
- [ ] 20.3 Document potential next steps:
  - [ ] 20.3.1 Add Darwin support
  - [ ] 20.3.2 Migrate Home-Manager to dendritic pattern
  - [ ] 20.3.3 Add more factory aspects as patterns emerge
  - [ ] 20.3.4 Consider splitting large features

## 12. Migrate hosts/ to modules/hosts/ (Host Features)
- [x] 12.0 Note: Profiles are redundant (1:1 mapping to hosts)
  - [x] 12.0.1 profiles/Work/ = technative-casper host
  - [x] 12.0.2 profiles/Gaming/ = gaming-casper host
  - [x] 12.0.3 profiles/Personal/ = personal-casper host
  - [x] 12.0.4 profiles/Server/ = server-casper host
  - [x] 12.0.5 Each host absorbs its profile logic through imports
- [x] 12.1 Understand variables.nix replacement patterns:
  - [x] 12.1.1 User data (git username/email) → Use systemConstants
  - [x] 12.1.2 Program choices (browser, terminal) → Import appropriate features
  - [x] 12.1.3 UI preferences (waybarChoice) → Configure in feature modules
- [x] 12.2 Create `modules/hosts/technative-casper [N]/`
  - [x] 12.2.1 Create directory structure
  - [x] 12.2.2 Create `hardware.nix` following mipnix pattern:
    - [x] Migrate from `hosts/technative-casper/hardware-configuration.nix`
    - [x] Expose as `flake.modules.nixos.technative-casper` (contributes to same module)
    - [x] Include boot configuration, file systems, LUKS, hardware-specific settings
    - [x] Reference: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/hardware.nix
  - [x] 12.2.3 Create `configuration.nix` following mipnix pattern:
    - [x] Declare `flake.nixosConfigurations.technative-casper` using `self.lib.makeNixos`
    - [x] Expose `flake.modules.nixos.technative-casper` (same module as hardware.nix)
    - [x] Use `imports = with inputs.self.modules.nixos; [...]` to compose features
    - [x] Import services from profiles/Work/ (tailscale, docker, openvpn, etc.)
    - [x] Import desktop (hyprland)
    - [x] Import packages (essentials, gui, technative)
    - [x] Add host-specific config (networking.hostName, system.stateVersion, etc.)
    - [x] Reference: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/configuration.nix
  - [x] 12.2.4 ❌ Remove `hosts/technative-casper/variables.nix`:
    - [x] Git config now from systemConstants
    - [x] Program choices from imported features
  - [x] 12.2.5 ✅ Create `flake-parts.nix` to declare nixosConfiguration (separate from module content)
- [x] 12.3 Create `modules/hosts/gaming-casper [N]/`
  - [x] Create `hardware.nix` (from hosts/gaming-casper/hardware-configuration.nix)
  - [x] Create `configuration.nix` (declares nixosConfiguration + module)
  - [x] Absorb profile logic from profiles/Gaming/ through imports
  - [x] Import gaming-specific services (syncthing, etc.)
  - [x] Import gaming packages
- [x] 12.4 Create `modules/hosts/personal-casper [N]/`
  - [x] Create `hardware.nix` (from hosts/personal-casper/hardware-configuration.nix)
  - [x] Create `configuration.nix` (declares nixosConfiguration + module)
  - [x] Absorb profile logic from profiles/Personal/ through imports
- [x] 12.5 Create `modules/hosts/server-casper [N]/`
  - [x] Create `hardware.nix` (from hosts/server-casper/hardware-configuration.nix)
  - [x] Create `configuration.nix` (declares nixosConfiguration + module)
  - [x] Absorb profile logic from profiles/Server/ through imports
  - [x] Configure for aarch64-linux system
- [x] 12.6 Remove `parts/nixos.nix` from flake.nix imports:
  - [x] Hosts now self-contained and auto-discovered via import-tree
  - [x] No need for central nixosConfigurations declaration
- [x] 12.6.1 Fix import-tree discovery issue:
  - [x] Discovered that directory names with spaces break import-tree
  - [x] Renamed all host directories from `"hostname [N]"` to `hostname` (no spaces)
  - [x] Created separate flake-parts.nix files for nixosConfiguration declarations
  - [x] Verified all 4 hosts are now discovered: `nix eval .#nixosConfigurations --apply builtins.attrNames`
  - [x] Result: `[ "gaming-casper" "personal-casper" "server-casper" "technative-casper" ]`
- [x] 12.6.2 Fix module name mismatches:
  - [x] Fixed `syncthing-client` → `syncthing` in personal-casper and gaming-casper
- [ ] 12.7 Rename `hosts/` to `_oldhosts/` directory (after user confirms successful migration)
- [ ] 12.8 Rename `profiles/` to `_oldprofiles/` directory (after user confirms successful migration)

**Note**: Following mipnix/dendritic-design pattern:
- **flake-parts.nix** - Declares `flake.nixosConfigurations.<hostname>` using `self.lib.makeNixos`
- **configuration.nix** - Defines `flake.modules.nixos.<hostname>` with system configuration and feature imports
- **hardware.nix** - Defines `flake.modules.nixos.<hostname>` with hardware-specific settings
- flake-parts automatically merges multiple definitions of the same module
- CRITICAL: Directory names must NOT contain spaces (e.g., use `technative-casper` not `technative-casper [N]`) for import-tree to discover them


## 18. Cleanup
- [ ] 18.1 Verify directory structure (after user confirms migration success):
  - [x] 18.1.1 `modules/` directory (COMPLETE - 62 dendritic modules)
  - [x] 18.1.2 `secrets/` directory (preserved)
  - [x] 18.1.3 `overlays/` directory (preserved)
  - [x] 18.1.4 `home/` directory (kept, not migrated)
  - [x] 18.1.5 `flake.nix` and `flake.lock` (updated)
  - [ ] 18.1.6 `_oldparts/` (to be created after user confirms)
  - [ ] 18.1.7 `_oldhosts/` (to be created after user confirms)
  - [ ] 18.1.8 `_oldprofiles/` (to be created after user confirms)
- [ ] 18.2 Rename old directories for backup (AFTER USER CONFIRMS MIGRATION SUCCESS):
  - [ ] 18.2.1 `mv parts _oldparts` (keep parts/home-manager.nix for now)
  - [ ] 18.2.2 `mv hosts _oldhosts`
  - [ ] 18.2.3 `mv profiles _oldprofiles`
- [ ] 18.3 Update .gitignore to exclude _old* directories:
  - [ ] 18.3.1 Add `_old*/` to .gitignore
- [x] 18.4 Verify `modules/etc/` migrated to proper locations
- [x] 18.5 All modules migrated and syntax errors fixed
- [ ] 18.6 Document that _old* directories can be removed after production verification

**IMPORTANT**: Wait for user to test and confirm migration success before renaming directories to _old*


