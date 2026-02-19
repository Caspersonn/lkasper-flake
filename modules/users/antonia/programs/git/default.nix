{ ... }: {
  flake.modules.homeManager.antonia-git = { ... }: {
    # Git configuration  
    programs.git = {
      enable = true;
      settings = {
        user = {
          email = "antoniagosker@gmail.com";
          name = "antonia";
        };
        push = {
          autoSetupRemote = true;
          default = "simple";
        };
        branch = { autosetupmerge = true; };
        pull = { rebase = true; };
        merge = { tool = "splice"; };
      };
    };
  };
}
