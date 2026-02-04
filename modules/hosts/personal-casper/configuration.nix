{ inputs, self, ... }:

let hostname = "personal-casper";

in {
  flake.nixosConfigurations = {
    personal-casper = self.lib.makeNixos {
      inherit hostname;
      stdenv.hostPlatform.system = "x86_64-linux";
    };
  };

  flake.modules.nixos.personal-casper = { config, pkgs, lib, ... }: {
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

      # Programs - GUI Apps
      gui-apps

      # Programs - Work
      technative

      # Programs - System
      hardware-utils
      disk-utils
      fonts

      # Services
      resolved
      tailscale
      syncthing
      mysql

      # System
      secrets
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "personal-casper";

    # LUKS encryption (host-specific)
    boot.initrd.luks.devices."luks-a295b140-6310-4699-9853-1ad5af5747f0".device =
      "/dev/disk/by-uuid/a295b140-6310-4699-9853-1ad5af5747f0";

    # i2c for DDC/CI (host-specific)
    hardware.i2c.enable = true;

    # Thunderbolt (host-specific)
    services.hardware.bolt.enable = true;

    # Epson printer drivers (host-specific)
    services.printing.drivers = with pkgs; [ epson-escpr2 epson-escpr ];
  };
}
