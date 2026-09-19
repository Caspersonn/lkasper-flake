{ inputs, self, ... }:

let hostname = "kaito";

in {
  flake.nixosConfigurations = {
    kaito = self.lib.makeNixos {
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

  casper.nebula.nodes.kaito = {
    address = "10.123.0.1";
    groups = [ "servers" ];
    isLighthouse = true;
    endpoints = [
      "vaultwarden.inspiravita.com:4242"
    ];
  };

  flake.modules.nixos.kaito = { config, pkgs, lib, ... }: {
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
      casper

      # Programs - CLI Tools
      cli-tools

      # Programs - Server
      server-tools

      # Services
      resolved
      tailscale
      networking-nebula
      docker
      smb
      atuin
      bluetooth-receiver
      postgres
      #rtcwake

      # Tools
      acme
      vaultwarden
      nextcloud
      #materialious
      #invidious
      #minecraft-server
      skyblock-minecraft
      wireguard-server
      home-assistant
      aiostreams
      adguardhome
      navidrome

      # System
      secrets
    ];

    # State version
    system.stateVersion = "25.11";

    networking.hostName = hostname;
    programs.dconf.enable = true;

    networking.firewall.allowedTCPPorts = [ 53 443 80 51820 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.xserver.displayManager.gdm.autoSuspend = false;
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    services.pipewire.jack.enable = true;
    nix.settings.download-buffer-size = 524288000;
  };
}
