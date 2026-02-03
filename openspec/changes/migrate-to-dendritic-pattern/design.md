# Design: Dendritic Pattern Migration (NixOS Only)

## Context

The current NixOS flake already uses flake-parts for basic organization:
- `flake.nix` imports parts from `parts/*.nix` using `flake-parts.lib.mkFlake`
- `parts/systems.nix` - Defines supported systems (x86_64-linux, aarch64-linux)
- `parts/formatter.nix` - Defines formatter using perSystem
- `parts/overlays.nix` - Provides `flake.lib.importFromChannelForSystem` helper
- `parts/nixos.nix` - Uses `makeNixosConf` helper to create nixosConfigurations
- `parts/home-manager.nix` - Uses `makeHomeConf` helper to create homeConfigurations

**Current structure**:
- Hosts import profiles (Work, Gaming, Personal, Server)
- Profiles import modules (services, packages, desktop-environments)
- Home-manager is integrated per-host with configurations in `home/`
- Code is organized by type (services/, packages/, home/programs/)
- Desktop environment selection uses boolean flags (gnome, hyprland, cosmic, kde)
- **Profiles are redundant**: Each maps 1:1 to a host
  - profiles/Work/ = technative-casper
  - profiles/Gaming/ = gaming-casper
  - profiles/Personal/ = personal-casper
  - profiles/Server/ = server-casper

**What's missing for dendritic pattern**:
- No `flake.modules` for feature composition
- No `vic/import-tree` for automatic feature discovery (usage: `inputs.import-tree ./modules`)
- makeNixosConf uses specialArgs and boolean flags instead of composable features
- Features not structured as reusable, general modules

We're migrating **NixOS configuration only** to the Dendritic Pattern which:
- Extends existing flake-parts usage to leverage `flake.modules`
- Inverts the configuration matrix (bottom-up instead of top-down)
- Uses features as the primary unit of composition
- Features define **general modules** usable by any NixOS system
- Users can import and customize features through home-manager integration
- Uses all 8 dendritic aspect patterns as appropriate

### Constraints
- **Scope**: NixOS configuration only - Home-Manager stays in `home/` for now
- Must maintain all current functionality
- Must support 4 existing hosts (technative-casper, gaming-casper, personal-casper, server-casper)
- Must preserve secrets management with agenix
- Must maintain hardware-specific configurations
- Features should be general and reusable across different users/hosts
- User-specific customizations go in user modules, not feature modules
- **Preserve old directories** with _old prefix for safe migration

### Stakeholders
- Primary user (casper) - personal and work machines
- Future: potential Darwin/MacOS hosts (foundation prepared, not implemented)

## Goals / Non-Goals

### Goals
- Implement complete dendritic pattern for NixOS configuration
- Create reusable features that define general, composable modules
- Structure modules/ directory following dendritic conventions
- Enable user-level customization through feature imports
- Reduce code duplication significantly
- Simplify host definitions to feature composition
- Enable easy addition of new hosts or features
- Document pattern usage for future maintenance
- Apply all 8 aspect patterns where appropriate
- **Safely preserve old directories** as _old* backups

### Non-Goals
- Migrating Home-Manager configurations to dendritic pattern (keep in `home/` as-is)
- Adding Darwin support (prepare architecture, don't implement)
- Migrating to NixVim or other specialized frameworks
- Refactoring individual feature configurations (keep current settings)
- Changing secrets management approach
- Modifying desktop environment functionality (only structure changes)
- Permanently deleting old directories (rename to _old* for safety)

## Decisions

### Decision 1: NixOS Only Migration Scope
**Why**: Focus on mastering dendritic pattern for NixOS first, Home-Manager can be migrated later as a separate change

**Alternatives considered**:
- Full migration including Home-Manager - Too large, higher risk
- No migration - Misses benefits of dendritic pattern

**Implications**:
- `home/` directory stays as-is
- Features may include home-manager aspects (Multi-Context Aspect) when appropriate
- User modules can customize home-manager through imports

### Decision 2: Only 3 Top-Level Directories + Backup Strategy

**Final structure after migration**:
```
lkasper-flake/
├── flake.nix
├── modules/           # ALL configuration
├── secrets/           # Agenix secrets
├── overlays/          # Nixpkgs overlays
├── home/              # (kept, not migrated)
├── _oldparts/         # BACKUP: Original parts/
├── _oldhosts/         # BACKUP: Original hosts/
└── _oldprofiles/      # BACKUP: Original profiles/
```

**Directory naming convention** (suffix in brackets):
- `[N]` = NixOS only
- `[D]` = Darwin only  
- `[ND]` = NixOS + Darwin
- `[nd]` = nixos + darwin + homeManager
- `[networkInterfaces]`, etc. = Special DRY aspects

**Why**: 
- Clean, simple structure
- All features in one place
- Follows Doc-Steve's pattern
- **Safe migration** - old directories preserved for rollback

### Decision 3: All 8 Dendritic Aspect Patterns

Apply aspect patterns based on feature requirements:

| Aspect Pattern | Use Case | Example |
|----------------|----------|---------|
| **Simple Aspect** | Basic feature, direct config | Service modules, package collections |
| **Multi-Context Aspect** | System + home-manager config | Desktop environments, shell programs |
| **Inheritance Aspect** | Compose other features | Hosts, user modules |
| **Conditional Aspect** | Platform-specific (Linux vs Darwin) | Packages with platform variants |
| **Collector Aspect** | Aggregate from other features | Syncthing peer IDs, network routes |
| **Constants Aspect** | Shared values across features | systemConstants (admin email, etc.) |
| **DRY Aspect** | Reusable attribute components | Network interface configurations |
| **Factory Aspect** | Parameterized features | User creation, CIFS mounts |

**Why**: Each pattern solves specific composition needs, using all 8 provides maximum flexibility

**Key principle**: Features are **enabled by importing them**, not by setting `enable = true` flags. No `lib.mkEnableOption` or `lib.mkIf` needed for basic features.

**Example - Simple Aspect**:
```nix
# modules/services/syncthing [N]/syncthing.nix
{
  flake.modules.nixos.syncthing = {
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
    };
  };
}

# modules/hosts/gaming-casper [N]/configuration.nix
{ inputs, ... }:
{
  flake.modules.nixos.gaming-casper = {
    imports = with inputs.self.modules.nixos; [
      syncthing  # Feature enabled by importing
      tailscale
      hyprland
    ];
  };
}
```

**Why**: Simpler than option-based approach, features are self-contained, composition through imports

### Decision 4: Features as Direct NixOS Configuration

**Pattern**: 
- Features define **direct NixOS/home-manager configuration** 
- No `mkEnableOption` or `mkIf` wrappers needed
- Features are enabled by **importing them** in host configurations
- Host modules compose features using `imports = with inputs.self.modules.nixos; [...]`

**Example - Simple service**:
```nix
# modules/services/tailscale [N]/tailscale.nix
{
  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
    };
  };
}
```

**Example - Package collection**:
```nix
# modules/packages/essentials [N]/essentials.nix
{ pkgs, ... }:
{
  flake.modules.nixos.essentials = {
    environment.systemPackages = with pkgs; [
      htop
      git
      vim
    ];
  };
}
```

**Example - Host composing features**:
```nix
# modules/hosts/gaming-casper [N]/configuration.nix
{ inputs, ... }:
{
  flake.modules.nixos.gaming-casper = {
    imports = with inputs.self.modules.nixos; [
      # System features
      systemConstants
      essentials
      
      # Services
      tailscale
      syncthing
      
      # Desktop
      hyprland
    ];
  };
}
```

**Why**: 
- Simpler and more direct than option-based approach
- Features are self-contained modules
- Composition through imports is more flexible
- Follows Doc-Steve and mipnix patterns exactly

### Decision 5: Profiles are Redundant - Absorb Into Hosts

**Discovery**: Profiles map 1:1 to hosts - no separate system types needed

**Decision**: Host features directly import services/packages

**Why**: Eliminates redundant abstraction, clearer, simpler

### Decision 6: Use import-tree for Automatic Feature Discovery

**Current**: Already using flake-parts for basic structuring

**Add**:
- `flake-parts.flakeModules.modules` (enables flake.modules)
- vic/import-tree for automatic feature discovery
- Usage: `inputs.import-tree ./modules` to automatically import all feature modules

**Why**: 
- Automatic discovery eliminates manual import lists
- Features are automatically available when added to modules/
- Follows dendritic pattern best practices

### Decision 7: Factory Aspects for Parametrized Features

Create factory library for user, mount, and other parameterized patterns.

### Decision 8: Host Features Compose Everything Through Imports

Each host = feature module that composes other features via `imports` list

**Pattern**:
```nix
# modules/hosts/technative-casper [N]/configuration.nix
{ inputs, ... }:
{
  flake.modules.nixos.technative-casper = {
    imports = with inputs.self.modules.nixos; [
      # Inherit from system type (optional)
      system-desktop
      
      # Services
      tailscale
      docker
      openvpn
      
      # Programs
      hyprland
      essentials
      
      # User configurations
      user-casper
    ];
    
    # Host-specific overrides (minimal)
    networking.hostName = "technative-casper";
  };
}
```

**Why**: Simple composition through imports, no complex inheritance chains

### Decision 9: Hardware Configuration as Dendritic Module

**Pattern**: Migrate `hardware-configuration.nix` to dendritic modules following mipnix pattern

**Structure**:
```nix
# modules/hosts/technative-casper [N]/hardware.nix
{ lib, inputs, ... }:
{
  flake.modules.nixos.technative-casper = { config, pkgs, ... }: {
    # Boot configuration
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" ];
    boot.kernelModules = [ "kvm-amd" ];
    
    # File systems
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/...";
      fsType = "ext4";
    };
    
    # LUKS
    boot.initrd.luks.devices."luks-...".device = "/dev/disk/by-uuid/...";
    
    # Hardware-specific services
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
```

**Why**:
- Hardware config is part of host configuration, not separate
- Follows mipnix reference architecture exactly
- Enables composition (both hardware.nix and configuration.nix contribute to same `flake.modules.nixos.<hostname>`)
- Hardware-specific settings stay with the host module
- No need to import from old `hosts/` directory

**Reference**: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/hardware.nix

### Decision 10: Self-Contained Host Configurations

**Pattern**: Each host declares its own `flake.nixosConfigurations` following mipnix pattern

**Structure**:
```nix
# modules/hosts/technative-casper [N]/configuration.nix
{ inputs, self, ... }:

let
  hostname = "technative-casper";
in
{
  # Declare nixosConfiguration
  flake.nixosConfigurations = {
    technative-casper = self.lib.makeNixos {
      inherit hostname;
      system = "x86_64-linux";
    };
  };

  # Define the module
  flake.modules.nixos.technative-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      # Feature imports
      tailscale
      docker
      hyprland
    ];
    
    # Host-specific config
    networking.hostName = "technative-casper";
    system.stateVersion = "25.11";
  };
}
```

**Why**:
- Self-contained - host configuration declares everything
- No need for central `parts/nixos.nix` file
- Follows mipnix pattern exactly
- Automatic discovery via `import-tree`
- Hardware and configuration both contribute to same module

**Reference**: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/configuration.nix

### Decision 11: Helper Library Functions

Create lib.nix with importFromChannelForSystem and mkNixos helpers.

### Decision 12: Replace variables.nix with Dendritic Patterns

- User data → Constants Aspect
- Program choices → Feature imports
- UI preferences → Feature customization

### Decision 13: Secrets Integration Pattern

Secrets stay in feature modules using agenix.

### Decision 14: Preserve Old Directories as Backups

**Strategy**: Rename to _old* prefix instead of deleting

**Commands**:
```bash
mv parts _oldparts
mv hosts _oldhosts
mv profiles _oldprofiles
echo "_old*/" >> .gitignore
```

**Why**: Safety, easy rollback, can verify before permanent removal

### Decision 15: System Configuration Extraction

**Pattern**: Extract common system configuration from host files into reusable `modules/system/` modules

**Motivation**: Following mipnix pattern, host configurations should only contain:
- Host-specific configuration (hostname, LUKS devices, hardware-specific drivers)
- Feature imports
- State version

Common system configuration (locale, boot, networking, audio, graphics, users, etc.) should be extracted into reusable system modules that can be imported by hosts.

**Implementation**:
- Created 10 system modules in `modules/system/`:
  - `locale [N]/` - Timezone and i18n settings
  - `boot [N]/` - Systemd-boot bootloader
  - `networking [N]/` - NetworkManager configuration
  - `graphics [N]/` - Hardware graphics acceleration
  - `audio [N]/` - PipeWire audio stack
  - `bluetooth [N]/` - Bluetooth support
  - `xserver [N]/` - X11 windowing system basics
  - `openssh [N]/` - SSH server
  - `nixpkgs [N]/` - Nixpkgs config (allowUnfree, experimental features)
- Created 1 user module in `modules/users/`:
  - `casper [N]/` - User account definition

**Host Import Pattern**:
```nix
imports = with inputs.self.modules.nixos; [
  # System Configuration
  locale
  boot        # Optional: server uses custom bootloader
  networking
  graphics    # Optional: not needed for headless servers
  audio
  bluetooth
  xserver
  openssh
  nixpkgs
  casper

  # Feature modules
  hyprland
  docker
  # ...
];
```

**Benefits**:
- DRY: System configuration defined once, reused across all hosts
- Clarity: Host files only contain host-specific overrides
- Maintainability: Changes to common config affect all hosts automatically
- Flexibility: Hosts can skip modules they don't need (e.g., server skips graphics)

**Trade-offs**:
- Hosts must override conflicting settings explicitly
- Need to document which modules are optional vs required

**Reference**: https://github.com/mipmip/mipnix/tree/main/modules/system

### Decision 16: Simplified File Structure - Flat Files in Category Subdirectories

**Pattern**: Remove `[N]` directory wrappers and place files directly in category subdirectories

**Before (with [N] wrappers)**:
```
modules/services/atuin [N]/atuin.nix
modules/services/docker [N]/docker.nix
modules/services/networking/tailscale [N]/tailscale.nix
modules/programs/cli/tools [N]/tools.nix
modules/system/locale [N]/locale.nix
```

**After (flat in categories)**:
```
modules/services/tools/atuin.nix
modules/services/containers/docker.nix
modules/services/networking/tailscale.nix
modules/programs/cli/tools.nix
modules/system/locale.nix
```

**Key Changes**:
1. **Removed `[N]` directory wrappers** - Files are directly in parent directories
2. **Services organized by category** - `services/{backup,containers,databases,monitoring,networking,printing,security,system,tools}/`
3. **Programs organized by type** - `programs/{cli,desktop,dev,gaming,gui,server,system,work}/`
4. **System modules flattened** - `system/{locale,boot,networking,graphics,audio,bluetooth,xserver,openssh,nixpkgs}.nix`
5. **Users flattened** - `users/casper.nix`

**Rationale**:
1. **Cleaner**: One file per module, no extra directory nesting
2. **Simpler navigation**: Direct path to module file  
3. **No clutter**: No `[N]` markers in directory names
4. **Better organization**: Related services grouped in subdirectories
5. **Easier maintenance**: Fewer directories to manage

**Import-tree Compatibility**:
- Files must be git-tracked for Nix flakes to see them
- Files need `{ inputs, ... }:` wrapper for import-tree discovery
- Module names defined inside files (e.g., `flake.modules.nixos.tailscale`)
- Category structure doesn't affect module naming

**Benefits**:
- Reduced directory depth (2-3 levels vs 3-4 levels)
- Cleaner `ls` output (no `[N]` markers everywhere)
- Simpler file paths
- Logical grouping by function
- Easy to find related modules

**Implementation Details**:
- **Services**: Organized into 9 functional categories (see Decision 17)
- **Programs**: Organized into 8 type categories
- **System**: Flat files + 3 subdirectories (settings/, security/, hardware/)
- **All files wrapped** with `{ inputs, ... }:` for import-tree
- **Secret paths fixed**: Relative paths updated for new locations

### Decision 17: Service Categorization

**Pattern**: Organize services into logical subdirectories by function (following mipnix inspiration)

**Final Structure**:
```
modules/services/
├── backup/
│   ├── syncthing.nix
│   └── syncthing-server.nix
├── containers/
│   ├── docker.nix
│   ├── podman.nix
│   └── docker-stremio.nix
├── databases/
│   ├── mysql.nix
│   └── neo4j.nix
├── monitoring/
│   ├── monitoring.nix
│   ├── nix-healthchecks.nix
│   └── coolerd.nix
├── networking/
│   ├── tailscale.nix
│   ├── openvpn.nix
│   ├── wireguard.nix
│   └── resolved.nix
├── printing/
│   └── printing.nix
├── security/
│   └── smb.nix
├── system/
│   ├── fwupd.nix
│   ├── bluetooth-receiver.nix
│   └── flatpak.nix
└── tools/
    ├── atuin.nix
    ├── croctalk.nix
    ├── ollama.nix
    └── birthday.nix
```

**Categories** (9 total):
- `backup/` - File synchronization and backup (syncthing)
- `containers/` - Container runtimes (docker, podman, docker-stremio)
- `databases/` - Database services (mysql, neo4j)
- `monitoring/` - System monitoring and health checks (monitoring, nix-healthchecks, coolerd)
- `networking/` - VPN, DNS, network services (tailscale, openvpn, wireguard, resolved)
- `printing/` - Printing services
- `security/` - File sharing and security (smb)
- `system/` - System update services, package managers (fwupd, flatpak, bluetooth-receiver)
- `tools/` - CLI tools and utilities (atuin, croctalk, ollama, birthday)

**Rationale**:
- Clear functional grouping
- Easy to find related services
- Logical organization for 23+ services
- Similar services grouped together
- One level of subdirectories (not too deep)
- Extensible - easy to add new categories

**Benefits**:
- Organized structure scales well with service count
- Clear where to add new services
- Related services discoverable together
- Follows mipnix pattern while adding categorization

**Reference**: Inspired by mipnix flat structure but organized by category for better scalability

**Implementation Notes**:
- Total: **23 service modules** migrated
- All files are flat `.nix` files in category directories
- No `[N]` wrappers - files directly in categories
- Module names defined in file content (e.g., `flake.modules.nixos.tailscale`)
- Import-tree discovers all files via git tracking

## Migration Plan

### Phase 1: Infrastructure (2-3 days)
Migrate parts/, add dendritic tools, create modules/ structure

### Phase 2: Core System Features (3-4 days)
systemConstants, base system features

### Phase 3: Services & Settings (4-5 days)
Migrate all services to Simple Aspect features

### Phase 4: Programs & Packages (4-5 days)
Migrate programs with Multi-Context Aspect where needed

### Phase 5: Factory Aspects (2-3 days)
Create user and mount factories

### Phase 6: Hosts Migration (5-6 days)
Migrate hosts/, absorb profiles/, remove variables.nix

### Phase 7: Cleanup (2-3 days)
Rename old directories to _old*, update documentation

**Total estimated time**: 21-28 days (3-4 weeks)

## Risks / Trade-offs

- Large-scale restructure → Mitigate with phased approach
- variables.nix complexity → Document clear patterns
- Profile absorption → Clear mapping, reference _oldprofiles/
- Learning curve → Worth it for long-term benefits
- Safe rollback available via _old* directories
