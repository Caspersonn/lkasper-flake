{ ... }: {
  flake.modules.homeManager.shared-ragenx = { inputs, pkgs, ... }: {
    home.file = {
      ".config/" = {
        source = ./config;
        recursive = true;
      };
    };

    imports = [inputs.ragenx.homeManagerModules.default];
    programs.ragenx.enable = true;
  };
}
