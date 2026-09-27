{ inputs, self, ... }:

let hostname = "personal-casper";

in {
  flake.nixosConfigurations = {
    personal-casper = self.lib.makeNixos {
      inherit hostname;
      system = "x86_64-linux";
      enableFrameworkHardware = false;
    };
  };

  flake.homeConfigurations = {
    "casper@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      imports = with inputs.self.modules.homeManager; [ casper ];
    };
  };

  casper.nebula.nodes.personal-casper = {
    address = "10.123.0.52";
    groups = [ "workstations" ];
  };

  casper.wol = {
    client = true;
  };

  flake.modules.nixos.personal-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.spicetify-nix.nixosModules.default

      inputs.omarchy-nix.nixosModules.lkh-system
      inputs.omarchy-nix.nixosModules.lkh-hyprland
      # System Configuration
      system-default
      locale
      boot
      performance
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
      casper

      # Desktop Environment
      hyprland

      # Programs - CLI Tools
      cli-tools

      # Programs - Gaming
      gaming
      steam

      # Programs - dev
      dev-git
      dev-lsp
      dev-languages

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
      networking-nebula
      mysql
      flatpak
      postgres
      wireguard

      # System
      secrets
      hardware-udevddcutil
      hardware-printing
      twobluetooth
      hardware-wol
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "personal-casper";

    # LUKS encryption (host-specific)
    boot.initrd.luks.devices."luks-a295b140-6310-4699-9853-1ad5af5747f0".device =
      "/dev/disk/by-uuid/a295b140-6310-4699-9853-1ad5af5747f0";

    # WireGuard
    custom.wireguard.address = "10.100.0.2/24";
    custom.wireguard.privateKeySecret = "wireguard";
    custom.wireguard.secretFile = ../../../secrets/wireguard-private.age;

    # i2c for DDC/CI (host-specific)
    hardware.i2c.enable = true;

    # Thunderbolt (host-specific)
    services.hardware.bolt.enable = true;

    # Epson printer drivers (host-specific)
    services.printing.drivers = with pkgs; [ epson-escpr2 epson-escpr ];

    services.udisks2.enable = true;
    security.polkit.enable = true;

    hardware.firmware = [
      (pkgs.runCommandLocal "yellow-carp-dmcub-firmware" {
        src = pkgs.fetchurl {
          name = "yellow_carp_dmcub.bin";
          # tag 20260519 == f7c95a2f945e7ca5fd8f55c3ff3fe662bac24f65
          url =
            "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amdgpu/yellow_carp_dmcub.bin?id=f7c95a2f945e7ca5fd8f55c3ff3fe662bac24f65";
          hash = "sha256-smgZgXSAbKVR9kKjVFZyo+0oFFozhaoC2lDEIyDb6c8=";
        };
        meta.priority = 0;
      } ''
        install -Dm444 "$src" "$out/lib/firmware/amdgpu/yellow_carp_dmcub.bin"
      '')
    ];
  };
}
