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
    "lucak@${hostname}" = self.lib.makeHomeConf {
      username = "lucak";
      homedir = "/home/lucak";
      inherit hostname;
      imports = with inputs.self.modules.homeManager; [ lucak ];
    };
  };

  flake.modules.nixos.gaming-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.spicetify-nix.nixosModules.default

      # lkasper-hyprland
      inputs.omarchy-nix.nixosModules.lkh-system
      inputs.omarchy-nix.nixosModules.lkh-hyprland

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
      docker

      # Home manager
      hm-nixos
      hm-users
      casper
      lucak

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
      dev-ai
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
      ollama
      flatpak
      lact
      wireguard

      # System
      secrets
      udev-skylanders
      udev-ddcutil
      udev-logitech-wheel
    ];

    # WireGuard
    custom.wireguard.address = "10.100.0.4/24";
    custom.wireguard.privateKeySecret = "wireguard-gaming-casper";
    custom.wireguard.secretFile = ../../../secrets/wireguard-private-gaming-casper.age;

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
