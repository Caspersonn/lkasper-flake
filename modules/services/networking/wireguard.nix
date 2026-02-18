{ inputs, ... }: {
  flake.modules.nixos.wireguard = { config, ... }: {
    networking.firewall.allowedUDPPorts = [ 51820 ];

    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.secrets.wireguard.file = ../../../secrets/wireguard-private.age;

    networking.wg-quick.interfaces = {
      wgtechnative = {
        autostart = false;
        address = [ "10.0.0.2/24" ];
        privateKeyFile = config.age.secrets.wireguard.path;

        peers = [{
          publicKey = "CWdPTt8t7bRVzStETmU8J/QimhdwPTGVH0R0Fn/nPFg=";
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "82.172.137.171:51820";
          persistentKeepalive = 25;
        }];
      };

      wgcasper = {
        autostart = false;
        address = [ "10.100.0.2/24" ];
        privateKeyFile = config.age.secrets.wireguard.path;

        peers = [{
          publicKey = "REPLACE_WITH_SERVER_PUBLIC_KEY";
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "217.105.109.99:51820";
          persistentKeepalive = 25;
        }];
      };
    };
  };
}
