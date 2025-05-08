{config, pkgs, lib, ...}:

{
  programs.git = {
    enable = true;
    userEmail = "lucakasper8@gmail.com";
    userName = "Caspersonn";
    extraConfig = {
      push = { autoSetupRemote = true; };
      branch = { autosetupmerge = true; };
      push = { default = "simple"; };
      pull = { rebase = true;};
      merge = { tool = "splice"; };
    };
  };
}
