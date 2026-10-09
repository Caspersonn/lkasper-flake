{ ... }: {
  flake.modules.homeManager.shared-git = { ... }: {
    programs.git = {
      enable = true;
      settings = {
        push = {
          autoSetupRemote = true;
        };
        branch = { autoSetupMerge = "simple"; };
        pull = { rebase = true; };
        merge = { tool = "splice"; };
        push = { default = "current"; };
      };
    };

    programs.gh = {
      enable = true;
      gitCredentialHelper = {
        enable = true;
      };
    };
  };
}
