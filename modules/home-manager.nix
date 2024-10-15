{pkgs,config,...}: {
 home-manager.useGlobalPkgs = true;
 #home-manager.users.wtoorren = {
 # programs.home-manager.enable = true;
 #};

  home.shell = pkgs.zsh;
  programs.ssh.startAgent = true;
}
