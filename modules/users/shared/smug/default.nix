{ ... }: {
  flake.modules.homeManager.shared-smug = { ... }: {
    home.file = {
      ".config/smug" = {
        source = ./smug;
        recursive = true;
      };
    };
  };
}
