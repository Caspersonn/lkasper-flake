{inputs, ... }: {
  flake.modules.homeManager.scripts = { pkgs, config, lib, username, hostname, ... }:
    {
      home.file = {
        ".config/hypr/scripts" = {
          source = ./scripts;
          recursive = true;
          executable = true;
        };
      };
    };
}
