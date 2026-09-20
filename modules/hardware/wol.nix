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
    flake.modules.nixos.hardware-wol = { pkgs, ... }: lib.mkMerge [
      {
        environment.systemPackages = [ pkgs.wakeonlan ];
      }

      (lib.optionalAttrs (!cfg.client) {
        assertions = [{
          assertion = cfg.interface != null;
          message = "casper.wol.interface must be set when casper.wol.client is false.";
        }];

        networking.interfaces.${cfg.interface}.wakeOnLan.enable = true;
      })
    ];
  };
}
