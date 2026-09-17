{ ... }: {
  flake.modules.nixos.cato-client = { pkgs, config, ... }:
    {
      age = {
        secrets = {
          "nebula-arcana-one-key" = {
            file = ../secrets/nebula-arcana-one.key.age;
            path = "/var/lib/nebula/nebula-arcana-one.key";
            owner = "nebula-mesh";
            group = "root";
            mode = "600";
          };
          "nebula-arcana-one-cert" = {
            file = ../secrets/nebula-arcana-one.crt.age;
            path = "/var/lib/nebula/nebula-arcana-one.crt";
            owner = "nebula-mesh";
            group = "root";
            mode = "600";
          };
          "nebula-ca-cert" = {
            file = ../secrets/nebula-ca.crt.age;
            path = "/var/lib/nebula/nebula-ca.crt";
            owner = "nebula-mesh";
            group = "root";
            mode = "600";
          };
        };
      };

      environment.systemPackages = with pkgs; [ nebula ];
      services.nebula.networks.mesh = {
        enable = true;
        isLighthouse = false;
        cert = config.age.secrets.nebula-arcana-one-cert.path;
        key = config.age.secrets.nebula-arcana-one-key.path;
        ca = config.age.secrets.nebula-ca-cert.path;
        lighthouses = [ "192.168.200.1" ];
        staticHostMap = {
          "192.168.200.1" = [
            "54.93.81.45:4242"
          ];
        };
        firewall.inbound = [
          {
            host = "any";
            port = "any";
            proto = "any";
          }
        ];

        firewall.outbound = [
          {
            host = "any";
            port = "any";
            proto = "any";
          }
        ];
      };

      networking.firewall = {
        allowedUDPPorts = [ 4242 ];
      };
    };
}
