{ inputs, self, ... }:

let hostname = "neko";

in {
  flake.nixosConfigurations = {
    neko = self.lib.makeNixos {
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

  flake.modules.nixos.neko = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      # System Configuration
      system-default
      locale
      boot
      graphics
      networking
      audio
      openssh
      nixpkgs
      age

      # Home Manager
      hm-nixos
      hm-users

      # Programs - CLI Tools
      cli-tools

      # Programs - Server
      server-tools

      # Services
      resolved
      tailscale
      docker
      smb
      atuin
      bluetooth-receiver
      postgres

      # Tools
      pokemon-tracker
      acme
      vaultwarden
      nextcloud

      # System
      secrets
    ];

    # State version
    system.stateVersion = "25.11";

    networking.hostName = "neko";
    programs.dconf.enable = true;

    services.xserver.displayManager.gdm.autoSuspend = false;
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    services.pipewire.jack.enable = true;
  };
}
