{ inputs, self, ... }:

let hostname = "sakura";

in {
  flake.nixosConfigurations = {
    sakura = self.lib.makeNixos {
      inherit hostname;
      stdenv.hostPlatform.system = "x86_64-linux";
    };
  };

  flake.homeConfigurations = {
    "antonia@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      username = "antonia";
      homedir = "/home/antonia";
      imports = with inputs.self.modules.homeManager; [ antonia ];
    };
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
      coolerd
      resolved
      tailscale
      flatpak

      # System
      udev-ddcutil
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "sakura";

    # AMD GPU driver (host-specific)
    services.xserver.videoDrivers = [ "amdgpu" ];

    # Storage and USB management (host-specific)
    services.udisks2.enable = true;
    security.polkit.enable = true;
  };
}
