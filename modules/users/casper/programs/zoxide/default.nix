{ ... }: {
  flake.modules.homeManager.casper-zoxide = { ... }: {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
