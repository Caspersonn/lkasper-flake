{ inputs, self, ... }:

let hostname = "server-casper";

in {
  flake.nixosConfigurations = {
    server-casper = self.lib.makeNixos {
      inherit hostname;
      system = "aarch64-linux";
      enableFrameworkHardware = false;
    };
  };

  flake.homeConfigurations = {
    "casper@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      imports = with inputs.self.modules.homeManager; [ casper ];
    };
  };

  flake.modules.nixos.server-casper = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      # System Configuration (Note: no boot/graphics - ARM server has custom bootloader)
      locale
      networking
      audio
      openssh
      nixpkgs
      casper
      system-default
      age
      hm-nixos

      # Programs - CLI Tools
      cli-tools

      # Programs - Server
      server-tools

      # Services
      resolved
      tailscale
      docker
      smb
      syncthing-server
      atuin
      bluetooth-receiver

      # System
      secrets
    ];

    # State version
    system.stateVersion = "25.11";

    # Host-specific configuration
    networking.hostName = "server-casper";

    # ARM Raspberry Pi bootloader (host-specific - no standard boot module)
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    # Emulation support for x86_64 (host-specific)
    boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

    # Disable automatic suspend (server should stay awake)
    services.xserver.displayManager.gdm.autoSuspend = false;
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    # Enable JACK for audio (server-specific)
    services.pipewire.jack.enable = true;
  };
}
