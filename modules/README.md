# Dendritic NixOS Configuration

This directory contains all NixOS configuration following the **Dendritic Pattern** - a composable, feature-based architecture.

## Philosophy

The dendritic pattern inverts traditional NixOS configuration:
- **Traditional**: Hosts have features (top-down)
- **Dendritic**: Features are imported by hosts (bottom-up)

Features are **direct NixOS configuration modules** that are composed through `imports`, not enabled through options.

## Directory Structure

```
modules/
├── hosts/              # Host configurations (4 hosts)
│   └── <hostname> [N]/
│       ├── configuration.nix  # Declares nixosConfiguration + imports features
│       └── hardware.nix       # Hardware-specific config (same module)
├── services/           # Service features (23 modules)
│   └── <service> [N]/
│       └── <service>.nix
├── programs/           # Program features (22 modules)
│   ├── cli/            # CLI tools
│   ├── desktop/        # Desktop environments (hyprland, gnome, kde, cosmic)
│   ├── dev/            # Development tools (git, languages, lsp)
│   ├── gaming/         # Gaming programs (steam, retroarch)
│   ├── gui/            # GUI applications
│   ├── server/         # Server tools
│   ├── system/         # System utilities (fonts, hardware-utils, disk-utils)
│   └── work/           # Work-specific tools
├── system/             # System configuration (9 modules)
│   ├── settings/       # System settings
│   │   └── systemConstants/  # Constants Aspect
│   ├── security/       # Security features (secrets)
│   └── hardware/       # Hardware rules (udev)
├── nix/                # Nix infrastructure
│   ├── systems/        # Supported systems
│   ├── formatter/      # Code formatter
│   └── lib/            # Helper functions (makeNixos)
├── factory/            # Factory aspects (optional, not populated)
├── users/              # User features (optional, not populated)
└── _legacy/            # Original modules (preserved for reference)
```

## Naming Convention

Directory suffixes indicate supported platforms:
- `[N]` - NixOS only
- `[D]` - Darwin only
- `[ND]` - NixOS + Darwin
- `[nd]` - nixos + darwin + homeManager

## Pattern: Simple Aspect (Most Common)

Features provide direct NixOS configuration. No `mkEnableOption` or `mkIf` wrappers.

**Service Example:**
```nix
# modules/services/tailscale [N]/tailscale.nix
{
  flake.modules.nixos.tailscale = { config, pkgs, ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "server";
      };
    };
}
```

**Usage:**
```nix
# Host imports feature to enable it
imports = with inputs.self.modules.nixos; [
  tailscale  # Feature enabled by importing
];
```

## Pattern: Host Configuration

Each host declares its own `nixosConfiguration` and imports features it needs.

**Structure:**
```nix
# modules/hosts/technative-casper [N]/configuration.nix
{ inputs, self, ... }:

let hostname = "technative-casper";
in
{
  # Declare nixosConfiguration
  flake.nixosConfigurations = {
    technative-casper = self.lib.makeNixos {
      inherit hostname;
      system = "x86_64-linux";
    };
  };

  # Define the module (same module as hardware.nix)
  flake.modules.nixos.technative-casper = { config, pkgs, lib, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Desktop
        hyprland
        
        # Services
        tailscale
        docker
        
        # Programs
        cli-tools
        dev-git
      ];
      
      # Host-specific config
      networking.hostName = "technative-casper";
      system.stateVersion = "25.11";
      # ... other config
    };
}
```

**Hardware Configuration:**
```nix
# modules/hosts/technative-casper [N]/hardware.nix
{ lib, inputs, ... }:
{
  # Contributes to SAME module as configuration.nix
  flake.modules.nixos.technative-casper = { config, pkgs, modulesPath, ... }:
    {
      # Hardware config (boot, filesystems, etc.)
    };
}
```

**Key Points:**
- Both `configuration.nix` and `hardware.nix` contribute to the **same module**
- Configuration declares the `nixosConfiguration`
- Hardware provides hardware-specific settings
- Module composition via flake-parts merges them automatically

## Available Hosts

1. **technative-casper** - Work laptop (x86_64, Framework AMD 7040)
2. **gaming-casper** - Gaming desktop (x86_64, AMD GPU)
3. **personal-casper** - Personal laptop (x86_64, Framework)
4. **server-casper** - ARM server (aarch64, Raspberry Pi)

## Building Hosts

```bash
# Test build
nixos-rebuild build --flake .#technative-casper

# Switch to configuration
sudo nixos-rebuild switch --flake .#technative-casper

# Check all hosts
nix flake check
```

## Adding a New Feature

1. **Create the module:**
   ```bash
   mkdir -p "modules/services/myservice [N]"
   ```

2. **Write the feature:**
   ```nix
   # modules/services/myservice [N]/myservice.nix
   {
     flake.modules.nixos.myservice = { config, pkgs, ... }:
       {
         # Direct NixOS configuration
         services.myservice.enable = true;
       };
   }
   ```

3. **Import in host:**
   ```nix
   imports = with inputs.self.modules.nixos; [
     myservice  # Automatically discovered by import-tree
   ];
   ```

## Helper Functions

### `self.lib.makeNixos`

Creates a NixOS system configuration with common settings.

**Location:** `modules/nix/lib/flake-parts.nix`

**Parameters:**
- `hostname` - Host name (matches module name)
- `system` - System architecture (default: "x86_64-linux")
- `username` - User name (default: "casper")
- `enableFrameworkHardware` - Include Framework hardware support (default: true)

**Usage:**
```nix
flake.nixosConfigurations.technative-casper = self.lib.makeNixos {
  hostname = "technative-casper";
  system = "x86_64-linux";
};
```

## Automatic Discovery

All modules are automatically discovered using `import-tree`:
```nix
# flake.nix
imports = [
  flake-parts.flakeModules.modules
  (inputs.import-tree ./modules)  # Auto-discovers all features
];
```

## Module Statistics

- **Total dendritic modules:** 62
- **Services:** 23 modules
- **Programs:** 22 modules
- **System modules:** 9 modules
- **Hosts:** 4 configurations

## Reference Architecture

This implementation follows the **mipnix** dendritic pattern:
- Reference: https://github.com/mipmip/mipnix
- Host pattern: https://github.com/mipmip/mipnix/blob/main/modules/hosts/lego2-laptop/
- Features are direct NixOS configuration
- Composition through imports, not options

## Migration Notes

**Completed:**
- ✅ All services migrated to dendritic modules
- ✅ All programs migrated and organized by category
- ✅ All hosts self-contained with hardware.nix
- ✅ Profiles absorbed into host configurations
- ✅ Hardware configurations migrated
- ✅ parts/nixos.nix removed (replaced by self-contained hosts)

**Preserved:**
- 📦 `home/` - Home-Manager (not migrated, separate concern)
- 📦 `parts/home-manager.nix` - Still used
- 📦 Original modules in `modules/_legacy/` (for reference)

**Pending User Action:**
- 🔄 Test host builds
- 🔄 Confirm migration success
- 🔄 Rename old directories: `hosts/` → `_oldhosts/`, `profiles/` → `_oldprofiles/`

## Troubleshooting

**Module not found:**
- Check module name matches directory name (e.g., `cli-tools` not `tools`)
- Verify `[N]` suffix in directory name
- Module must export `flake.modules.nixos.<name>`

**Build fails:**
```bash
# Check module syntax
nix flake check

# Show available outputs
nix flake show

# Test specific module
nix eval .#nixosConfigurations.technative-casper.config.system.build.toplevel
```

**Import errors:**
- Ensure using correct module namespace: `inputs.self.modules.nixos.<name>`
- Check that both hardware.nix and configuration.nix use same module name

## Next Steps (Optional)

1. **Home-Manager Migration** - Apply dendritic pattern to `home/` directory
2. **Factory Aspects** - Add user/mount factories if needed
3. **System Types** - Create system-minimal/cli/desktop if inheritance desired
4. **Darwin Support** - Add macOS configurations
5. **Cleanup** - Remove `_old*` directories after production verification
