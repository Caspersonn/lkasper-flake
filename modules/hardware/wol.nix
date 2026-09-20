{ config, lib, ... }:
let
  cfg = config.casper.wol;
in
{
  options.casper.wol = {
     interface = lib.mkOption {
      type = lib.types.str;
      description = "Interface to use for WOL";
    };

    client = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Client only";
    };

  };

  config = {
    flake.modules.nixos.hardware-wol = { pkgs, ... }: {
      networking = lib.optionals (cfg.client == false) {
        interfaces = {
          ${cfg.interface} = {
            wakeOnLan.enable = true;
          };
        };
        firewall = {
          allowedUDPPorts = [ 9 ];
        };
      };

      environment.systemPackages = with pkgs; [
        wakeonlan
      ];
    };
  };
}
