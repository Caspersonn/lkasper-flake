{ inputs, ... }: {
  flake.modules.nixos.hardware-utils = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      open-scq30
      epson-escpr
      epson-escpr2
      simple-scan
      sane-airscan
    ];

    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };

    services.avahi = {
      enable = true;
      openFirewall = true;
    };

    users.users.casper.extraGroups = [
      "scanner"
      "lp"
    ];
  };
}
