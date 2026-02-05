{ inputs, ... }: {
  flake.modules.nixos.pokemon-tracker = { config, lib, pkgs, unstable, ... }: {
    imports = [
        inputs.pokemon-tracker.nixosModules.default
    ];

    services.pokemon-tracker = {
      enable = true;
      port = 3000;
      host = "0.0.0.0";

      database = {
        name = "pokemon_tracker";
        user = "pokemon_tracker";
      };

      nextauth.secretFile = "/home/casper/lkasper-flake/test";

      allowedEmails = [
        "lucakasper8@gmail.com"
      ];
    };

    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
