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
  };

  flake.modules.nixos.technative-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd
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
      framework-misc
      framework-fingerprint
      system-default
      age
      hm-nixos

      # Desktop Environment
      hyprland

      # Programs - CLI Tools
      cli-tools

      # Programs - Development
      dev-git
      dev-languages
      dev-lsp

      # Programs - GUI Apps
      gui-apps
      chromium
      spotify
      bambu-labs

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

      # System
      secrets
      udev-ddcutil
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "technative-casper";

    # LUKS encryption (host-specific)
    boot.initrd.luks.devices."luks-f7326c24-daa8-457b-80b6-a47a0fe8f82c".device =
      "/dev/disk/by-uuid/f7326c24-daa8-457b-80b6-a47a0fe8f82c";

  };
}
