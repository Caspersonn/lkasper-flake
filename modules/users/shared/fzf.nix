{ ... }: {
  flake.modules.homeManager.shared-fzf = { ... }: {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
