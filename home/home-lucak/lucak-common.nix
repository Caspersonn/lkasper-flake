{config,pkgs,services,lib, ...}: 

{

programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
programs.firefox = {
    enable = true;
  };
 programs.jq = {
    enable = true;
  };
 
 programs.home-manager.enable = true;
 home.stateVersion = "24.11";
 home.username = "lucak";
 home.packages = with pkgs; [];

home.sessionVariables = {
    LANG= "en_US.UTF-8";
    LC_ALL= "en_US.UTF-8";
  };

#  home.file.".togglrcnew".source = "/tmp/toggl.txt";

home.shellAliases = {
  tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
};

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}
