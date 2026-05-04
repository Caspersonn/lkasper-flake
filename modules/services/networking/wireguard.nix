{ inputs, ... }: {
  flake.modules.nixos.wireguard = { config, lib, ... }: {
    options.custom.wireguard = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "WireGuard tunnel address for this host";
      };
      privateKeySecret = lib.mkOption {
        type = lib.types.str;
        default = "wireguard";
        description = "Name of the agenix secret for the WireGuard private key";
      };
      secretFile = lib.mkOption {
        type = lib.types.path;
        default = ../../../secrets/wireguard-private.age;
        description = "Path to the age-encrypted private key file";
      };
    };

    config = let cfg = config.custom.wireguard; in {
      networking.firewall.allowedUDPPorts = [ 51820 ];

    #<<<<<<< HEAD
    #        peers = [{
    #          publicKey = "7Ms/wNUDFUB+tN9tGnLtR6WiVNix1clFvNfm9sJfJxE=";
    #          allowedIPs = [ "0.0.0.0/0" "::/0" ];
    #          endpoint = "77.175.230.128:51820";
    #          persistentKeepalive = 25;
    #        }];
    #=======
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      age.secrets.${cfg.privateKeySecret}.file = cfg.secretFile;

      networking.wg-quick.interfaces = {
        wgtechnative = {
          autostart = false;
          address = [ cfg.address ];
          privateKeyFile = config.age.secrets.${cfg.privateKeySecret}.path;

          peers = [{
            publicKey = "CWdPTt8t7bRVzStETmU8J/QimhdwPTGVH0R0Fn/nPFg=";
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            endpoint = "82.172.137.171:51820";
            persistentKeepalive = 25;
          }];
        };

        wgcasper = {
          autostart = false;
          address = [ cfg.address ];
          privateKeyFile = config.age.secrets.${cfg.privateKeySecret}.path;

          peers = [{
            publicKey = "7Ms/wNUDFUB+tN9tGnLtR6WiVNix1clFvNfm9sJfJxE=";
            allowedIPs = [ "0.0.0.0/0" "::/0" ];
            endpoint = "77.175.230.128:51820";
            persistentKeepalive = 25;
          }];
        };
      };
    };
  };
}
