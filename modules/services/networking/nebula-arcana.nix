{ ... }:
{
  flake.modules.nixos.networking-nebula-arcana = { config, ... }:
    let
      secret = name: ../../../secrets + "/${name}";
      serviceUser = "nebula-arcana";
    in
    {
      networking.extraHosts = ''
        192.168.200.1 lighthouse1.arcana
        192.168.200.2 arcana-one.arcana
        192.168.200.10 post.arcana
        192.168.200.11 casper.arcana
      '';

      age.secrets = {
        nebula-arcana-ca-crt = {
          file = secret "nebula-arcana-ca.crt.age";
          owner = serviceUser;
          mode = "400";
        };
        nebula-arcana-crt = {
          file = secret "nebula-arcana-casper.crt.age";
          owner = serviceUser;
          mode = "400";
        };
        nebula-arcana-key = {
          file = secret "nebula-arcana-casper.key.age";
          owner = serviceUser;
          mode = "400";
        };
      };

      services.nebula.networks.arcana = {
        ca = config.age.secrets.nebula-arcana-ca-crt.path;
        cert = config.age.secrets.nebula-arcana-crt.path;
        key = config.age.secrets.nebula-arcana-key.path;

        isLighthouse = false;
        isRelay = false;
        lighthouses = [ "192.168.200.1" ];
        relays = [ "192.168.200.1" ];
        staticHostMap."192.168.200.1" = [ "54.93.81.45:4242" ];

        settings = {
          cipher = "aes";
          punchy = {
            punch = true;
            respond = true;
          };
        };

        firewall.outbound = [{
          host = "any";
          port = "any";
          proto = "any";
        }];
        firewall.inbound = [{
          host = "any";
          port = "any";
          proto = "any";
        }];
      };
    };
}
