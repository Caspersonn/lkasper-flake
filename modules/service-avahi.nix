{config, lib, pkgs, agenix, unstable, ... }:
	
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
