{pkgs, ...}:
let
  openvpn-location = "/home/casper/.cert/improvement_it";
in
{
  environment.systemPackages = [ pkgs.openvpn ];
  services.openvpn.servers = {
    client = {
      autoStart = false;
      config = ''
      client
      dev tun
      persist-tun
      persist-key
      data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-256-CBC
      data-ciphers-fallback AES-256-CBC
      auth SHA256
      tls-client
      client
      resolv-retry infinite
      remote 95.170.68.73 1195 tcp4
      nobind
      verify-x509-name "iit-vpn.improvement-it.nl" name
      auth-user-pass
      remote-cert-tls server
      proto tcp
      cert '${openvpn-location}/improvement.cert'
      key '${openvpn-location}/improvement.key'
      ca '${openvpn-location}/improvement.ca'
      tls-auth '${openvpn-location}/improvement-key.key' 1
      '';
      #up = "echo nameserver $nameserver | ${pkgs.openresolv}/sbin/resolvconf -m 0 -a $dev";
      #down = "${pkgs.openresolv}/sbin/resolvconf -d $dev";
    };
  };
}
