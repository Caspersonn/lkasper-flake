{ ... }:

{
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
        default = "simple";
      };
      branch = { autosetupmerge = true; };
      pull = { rebase = true; };
      merge = { tool = "splice"; };
    };
  };
}
