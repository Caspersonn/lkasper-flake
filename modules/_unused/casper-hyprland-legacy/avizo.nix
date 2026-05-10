{inputs, ... }: {
  flake.modules.homeManager.avizo = { pkgs, config, lib, username, hostname, ... }:
    {
      services.avizo = {
        enable = true;
        settings = {
          default = {
            time = 1.0;
            #y-offset = -0.5;
            fade-in = 0.1;
            fade-out = 0.2;
            padding = 10;
            background = "rgba(113, 98, 106, 0.8)";
          };
        };
      };
    };
}
