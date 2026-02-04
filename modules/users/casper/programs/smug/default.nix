{ ... }: {
  flake.modules.homeManager.casper-smug = { ... }: {
    home.file = {
      ".config/smug" = {
        source = ./smug;
        recursive = true;
      };
    };
  };
}
