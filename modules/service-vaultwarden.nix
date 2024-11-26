{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.vaultwarden = {
    enable = true;
    environmentFile = xxx; # Needs to be changed
    config = xxx; # Needs to be changed
  }

}
