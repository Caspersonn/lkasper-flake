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
 #home.stateVersion = "23.11";
 home.stateVersion = "24.05";
 home.username = "wtoorren";
 home.packages = with pkgs; [
  ];

home.sessionVariables = {
    LANG= "en_US.UTF-8";
    LC_ALL= "en_US.UTF-8";
  };

#  home.file.".togglrcnew".source = "/tmp/toggl.txt";


  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}