{ ... }: {
  flake.modules.homeManager.casper-git = { ... }: {
    # Git configuration  
    programs.git = {
      enable = true;
      settings = {
        user = {
          email = "lucakasper8@gmail.com";
          name = "Caspersonn";
        };
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
