{ inputs, self, ... }:

let hostname = "gaming-casper";

in {
  flake.nixosConfigurations = {
    gaming-casper = self.lib.makeNixos {
      inherit hostname;
      stdenv.hostPlatform.system = "x86_64-linux";
    };
  };

  flake.homeConfigurations = {
    "casper@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      imports = with inputs.self.modules.homeManager; [ casper ];
    };
  };

  flake.modules.nixos.gaming-casper = { config, pkgs, lib, ... }: {
    nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
    nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
    imports = with inputs.self.modules.nixos; [
      inputs.spicetify-nix.nixosModules.default

      # lkasper-hyprland
      inputs.omarchy-nix.nixosModules.omarchy-system
      inputs.omarchy-nix.nixosModules.omarchy-hyprland

      # System Configuration
      system-default
      locale
      boot
      networking
      graphics
      audio
      bluetooth
      xserver
      openssh
      nixpkgs
      age

      # Home manager
      hm-nixos
      hm-users

      # Remote building
      remote_builder
      binary-cache-signing

      # Desktop Environment
      hyprland

      # Programs - CLI Tools
      cli-tools

      # Programs - Gaming
      gaming
      steam
      retroarch

      # Programs - dev
      dev-git
      dev-lsp
      dev-languages

      # Programs - GUI Apps
      gui-apps
      spotify

      # Programs - System
      hardware-utils
      disk-utils
      fonts

      # Services
      coolerd
      resolved
      tailscale
      ollama
      flatpak
      mysql
      postgres

      # System
      secrets
      udev-skylanders
      udev-ddcutil
      udev-logitech-wheel
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "gaming-casper";

    # AMD GPU driver (host-specific)
    services.xserver.videoDrivers = [ "amdgpu" ];

    # Storage and USB management (host-specific)
    services.udisks2.enable = true;
    security.polkit.enable = true;
  };
}
