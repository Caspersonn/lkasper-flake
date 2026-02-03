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
    ];
  };
}
