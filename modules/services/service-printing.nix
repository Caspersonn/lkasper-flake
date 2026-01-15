{ pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    cups-brother-dcpl3550cdw
    cups-filters
  ];

  services.printing.drivers = [ pkgs.cups-brother-dcpl3550cdw ];
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
