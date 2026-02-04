{ inputs, self, ... }:

let hostname = "gaming-casper";

in {
  flake.nixosConfigurations = {
    gaming-casper = self.lib.makeNixos {
      inherit hostname;
      stdenv.hostPlatform.system = "x86_64-linux";
    };
  };

  flake.modules.nixos.gaming-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.spicetify-nix.nixosModules.default

      # System Configuration
      locale
      boot
      networking
      graphics
      audio
      bluetooth
      xserver
      openssh
      nixpkgs
      casper
      system-default
      age
      hm-nixos

      # Desktop Environment
      hyprland

      # Programs - CLI Tools
      cli-tools

      # Programs - Gaming
      gaming
      steam
      retroarch

      # Programs - GUI Apps
      gui-apps

      # Programs - System
      hardware-utils
      disk-utils
      fonts

      # Services
      coolerd
      resolved
      tailscale
      syncthing
      ollama
      flatpak
      mysql

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
