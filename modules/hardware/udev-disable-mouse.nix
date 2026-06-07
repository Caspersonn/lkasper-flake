{ ... }: {
  flake.modules.nixos.udev-disable-mouse = { ... }: {
    # This rule will disable sleep waking for the Logitech Pro Wireless
    # Bus 003 Device 006: ID 046d:c539 Logitech, Inc. Lightspeed Receiver
    services.udev = {
      enable = true;
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c539", ATTR{power/wakeup}="disabled"
        '';
    };
  };
}



