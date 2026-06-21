{ ... }: {
  flake.modules.nixos.adguardhome = { ... }: {
    services.adguardhome = {
      enable = true;
      host = "192.168.2.94";
      port = 3000;
      openFirewall = true;
      settings = {
        dhcp = {
          enabled = false;
          dhcpv4 = {
            gateway_ip = "192.168.2.254";
            subnet_mask = "255.255.255.0";
          };
        };

        dns = {
          bind_hosts = [
            "192.168.2.94"
            "10.100.0.1" # add only if you want DNS over that interface too
          ];
          port = 53;

          upstream_dns = [
            "https://dns.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
          ];
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          blocking_mode = "default";
          filters_update_interval = 24;
          blocked_response_ttl = 60;
        };

              # Pick a small number of good lists. More lists does not always mean better.
        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
            name = "AdGuard DNS filter";
            id = 1;
          }

          {
            enabled = true;
            url = "https://big.oisd.nl";
            name = "OISD Big";
            id = 2;
          }

          # Security-focused, medium-size threat list.
          {
            enabled = true;
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.medium.txt";
            name = "HaGeZi Threat Intelligence Feeds Medium";
            id = 3;
          }
        ];
      };
    };
    networking.firewall.interfaces.enp86s0 = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
    };
  };
}
