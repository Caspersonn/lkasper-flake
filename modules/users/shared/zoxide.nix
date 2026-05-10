{ ... }: {
  flake.modules.homeManager.shared-zoxide = { ... }: {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
