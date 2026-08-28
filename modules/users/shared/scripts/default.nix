{ ... }: {
  flake.modules.homeManager.shared-scripts = { ... }: {
    home.file = {
      "bin/" = {
        source = ./bin;
        recursive = true;
      };
    };
  };
}
