{ ... }: {
  flake.modules.homeManager.casper-atuin = { ... }: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://atuin.inspiravita.com";
        search_mode = "prefix";
      };
      flags = [ "--disable-up-arrow" ];
    };
  };
}
