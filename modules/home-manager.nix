{pkgs,config,...}: {
 home-manager.useGlobalPkgs = true;
 #home-manager.users.wtoorren = {
 # programs.home-manager.enable = true;
 #};

  programs.ssh.startAgent = true;
}
