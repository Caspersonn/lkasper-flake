{ inputs, ... }: {
  flake.modules.nixos.printing = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      cups-brother-dcpl3550cdw
      cups-filters
    ];

    services.printing = {
      enable = true;
      drivers = [ pkgs.cups-brother-dcpl3550cdw ];
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
