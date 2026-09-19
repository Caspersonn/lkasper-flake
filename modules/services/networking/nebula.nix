{ config, lib, ... }:
let
  cfg = config.casper.nebula;

  lighthouses = lib.mapAttrs' (_: node: lib.nameValuePair node.address node.endpoint) (
    lib.filterAttrs (_: node: node.isLighthouse) cfg.nodes
  );
  lighthouseIps = builtins.attrNames lighthouses;
in
{
  options.casper.nebula = {
    network = lib.mkOption {
      type = lib.types.str;
      default = "mesh";
      description = "Name of the nebula network.";
    };

    cidr = lib.mkOption {
      type = lib.types.str;
      default = "10.123.0.0/24";
      description = "Overlay network every node certificate is signed within.";
    };

    prefixLength = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Prefix length node certificates are signed with.";
    };

    nodes = lib.mkOption {
      default = { };
      description = "Mesh members, declared by each host in modules/hosts.";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          address = lib.mkOption {
            type = lib.types.str;
            description = "Overlay address, without prefix length.";
          };

          groups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Certificate groups, usable in firewall rules.";
          };

          isLighthouse = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this node is a lighthouse and relay.";
          };

          endpoint = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Reachable underlay \"host:port\". Required on a lighthouse.";
          };
        };
      });
    };
  };

  config = {
    flake.nebula = { inherit (cfg) network cidr prefixLength nodes; };

    flake.modules.nixos.networking-nebula = { config, lib, ... }:
      let
        host = config.networking.hostName;
        isLighthouse = cfg.nodes.${host}.isLighthouse;
        secret = name: ../../../secrets + "/${name}";
        serviceUser = "nebula-${cfg.network}";
      in
      {
        networking.extraHosts = lib.concatStrings (
          lib.mapAttrsToList (name: node: "${node.address} ${name}.${cfg.network}\n") cfg.nodes
        );

        age.secrets = {
          nebula-ca-crt = {
            file = secret "nebula-ca.crt.age";
            owner = serviceUser;
            mode = "400";
          };
          nebula-host-crt = {
            file = secret "nebula-${host}.crt.age";
            owner = serviceUser;
            mode = "400";
          };
          nebula-host-key = {
            file = secret "nebula-${host}.key.age";
            owner = serviceUser;
            mode = "400";
          };
        };

        services.nebula.networks.${cfg.network} = {
          ca = config.age.secrets.nebula-ca-crt.path;
          cert = config.age.secrets.nebula-host-crt.path;
          key = config.age.secrets.nebula-host-key.path;

          inherit isLighthouse;
          isRelay = isLighthouse;
          lighthouses = lib.optionals (!isLighthouse) lighthouseIps;
          relays = lib.optionals (!isLighthouse) lighthouseIps;
          staticHostMap = lib.mapAttrs (_address: endpoint: [ endpoint ]) lighthouses;

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
  };
}
