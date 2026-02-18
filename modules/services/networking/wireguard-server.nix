{ inputs, ... }: {
  flake.modules.nixos.wireguard-server = { config, ... }: {
    networking.firewall.allowedUDPPorts = [ 51820 ];

    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.secrets.wireguard-server.file = ../../../secrets/wireguard-server-private.age;

    # Enable IP forwarding for VPN routing
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.wg-quick.interfaces = {
      wgcasper = {
        address = [ "10.100.0.1/24" ];
        listenPort = 51820;
        privateKeyFile = config.age.secrets.wireguard-server.path;

        # NAT: masquerade VPN traffic leaving via the default interface
        postUp = ''
          iptables -A FORWARD -i wgcasper -j ACCEPT
          iptables -A FORWARD -o wgcasper -j ACCEPT
          iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        '';
        preDown = ''
          iptables -D FORWARD -i wgcasper -j ACCEPT
          iptables -D FORWARD -o wgcasper -j ACCEPT
          iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
        '';

        peers = [{
          publicKey = "REPLACE_WITH_CLIENT_PUBLIC_KEY";
          allowedIPs = [ "10.100.0.2/32" ];
        }];
      };
    };
  };
}
