{ config, ... }:
{
  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wireguard = {
    enable = true;
    interfaces = {
      # network interface name.
      # You can name the interface arbitrarily.
      wg0 = {
        # the IP address and subnet of this peer
        ips = [ "fd31:bf08:57cb::9/128" "10.100.0.2/32" ];

        # WireGuard Port
        # Must be accessible by peers
        listenPort = 51820;

        # Path to the private key file.
        #
        # Note: can also be included inline via the privateKey option,
        # but this makes the private key world-readable;
        # using privateKeyFile is recommended.
        privateKeyFile = "/home/casper/wireguard-keys/private";

        peers = [
          {
            name = "dreammachine";
            publicKey = "sIYuH2NUQFvEdRiPzfV+oHzoKWYd22ImCx38b+9LZj8=";
            allowedIPs = [
              "0.0.0.0/0"
            ];
            endpoint = "<ip_adres_work>:51820";
            #  ToDo: route to endpoint not automatically configured
            # https://wiki.archlinux.org/index.php/WireGuard#Loop_routing
            # https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577
            # Send keepalives every 25 seconds. Important to keep NAT tables alive.
            # persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
# it’s not imperative but it does not know how to do it :
# sudo ip route add 11.111.11.111 via 192.168.1.11 dev wlo1
# the ip adresse 11: external and 192: local.
