{ ... }: {
  flake.modules.homeManager.casper-fzf = { ... }: {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
