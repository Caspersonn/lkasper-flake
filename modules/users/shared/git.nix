{ ... }: {
  flake.modules.homeManager.shared-git = { ... }: {
    programs.git = {
      enable = true;
      settings = {
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        branch = { autoSetupMerge = "simple"; };
        pull = { rebase = true; };
        merge = { tool = "splice"; };
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
