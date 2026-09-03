{ inputs, ... }: {
  flake.modules.nixos.hardware-utils = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      android-tools
      ddcui
      libusb1
      usbutils
      sof-firmware
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

    # mDNS/DNS-SD discovery for network devices
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
