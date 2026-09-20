{ inputs, self, ... }:

let hostname = "sakura";

in {
  flake.nixosConfigurations = {
    sakura = self.lib.makeNixos {
      inherit hostname;
      system = "x86_64-linux";
    };
  };

  flake.homeConfigurations = {
    "antonia@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      username = "antonia";
      homedir = "/home/antonia";
      imports = with inputs.self.modules.homeManager; [ antonia ];
    };

    "casper@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      username = "casper";
      homedir = "/home/casper";
      imports = with inputs.self.modules.homeManager; [ casper ];
    };
  };

  casper.nebula.nodes.sakura = {
    address = "10.123.0.54";
    groups = [ "workstations" ];
  };

  casper.wol = {
    client = true;
  };

  flake.modules.nixos.sakura = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.spicetify-nix.nixosModules.default

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

      # Home manager
      hm-nixos
      hm-users
      antonia
      casper

      # Desktop Environment
      gnome

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
      spotify

      # Programs - System
      hardware-utils
      disk-utils
      fonts

      # Services
      age
      hardware-coolerd
      resolved
      tailscale
      networking-nebula
      flatpak
      wireguard

      # System
      hardware-udevddcutil
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "sakura";

    # WireGuard
    #custom.wireguard.address = "10.100.0.3/24";
    custom.wireguard.privateKeySecret = "wireguard-sakura";
    custom.wireguard.secretFile = ../../../secrets/wireguard-private-sakura.age;

    # AMD GPU driver (host-specific)
    services.xserver.videoDrivers = [ "amdgpu" ];

    # Storage and USB management (host-specific)
    services.udisks2.enable = true;
    security.polkit.enable = true;
  };
}
