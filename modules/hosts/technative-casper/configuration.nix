{ inputs, self, ... }:
let hostname = "technative-casper";

in {
  flake.nixosConfigurations.${hostname} = inputs.self.lib.makeNixos {
    inherit hostname;
    stdenv.hostPlatform.system = "x86_64-linux";
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

  flake.modules.nixos.technative-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd

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
      remote_builder

      # Hardware
      hardware-frameworkmisc
      hardware-frameworkfingerprint

      # Home manager
      hm-nixos
      hm-users
      casper

      # Desktop Environment
      hyprland

      # Programs - CLI Tools
      cli-tools

      # Programs - Development
      dev-android
      dev-git
      dev-languages
      dev-lsp
      dev-ai

      # Programs - GUI Apps
      gui-apps
      chromium
      spotify
      bambu-labs
      photoshop

      # Programs - Work
      technative

      # Programs - System
      hardware-utils
      disk-utils
      fonts
      nix-ld

      # Services
      resolved
      tailscale
      docker
      mysql
      openvpn
      wireguard
      neo4j
      printing
      reverse-proxy-claude
      #cato-client
      #llama-cpp

      # System
      secrets
      hardware-udevddcutil
      kdeconnect
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "technative-casper";

    # WireGuard
    custom.wireguard.privateKeySecret = "wireguard";
    custom.wireguard.secretFile = ../../../secrets/wireguard-private.age;

    # LUKS encryption (host-specific)
    boot.initrd.luks.devices."luks-f7326c24-daa8-457b-80b6-a47a0fe8f82c".device =
      "/dev/disk/by-uuid/f7326c24-daa8-457b-80b6-a47a0fe8f82c";

  };
}
