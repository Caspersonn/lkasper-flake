{ inputs, self, ... }:

let hostname = "arcana-one";

in {

  flake.homeConfigurations = {
    "casper@${hostname}" = self.lib.makeHomeConf {
      inherit hostname;
      imports = with inputs.self.modules.homeManager; [ casper ];
    };
  };

  flake.modules.nixos.${hostname} = { config, pkgs, lib, ... }: {
    imports = with inputs.self.modules.nixos; [
      # Home manager
      hm-nixos
      hm-users
    ];
  };
}
