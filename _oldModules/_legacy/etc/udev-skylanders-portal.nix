{config, lib, pkgs, agenix, unstable, ... }:
{
  services.udev = {
    enable = true;
    extraRules = 
    '' 
SUBSYSTEM=="usb", ATTRS{idVendor}=="1430", ATTRS{idProduct}=="0150", MODE="0666"
# DualShock 4 over USB
KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"

# DualShock 4 Wireless Adapter over USB
KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ba0", MODE="0666"

# DualShock 4 Slim over USB
KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"

# DualShock 4 over Bluetooth
KERNEL=="hidraw*", KERNELS=="*054C:05C4*", MODE="0666"

# DualShock 4 Slim over Bluetooth
KERNEL=="hidraw*", KERNELS=="*054C:09CC*", MODE="0666"
# Sysdvr
SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="4ee0", MODE="0666"

# ddcui
SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
SUBSYSTEM=="dri", KERNEL=="card[0-9]*", TAG+="uaccess"


    '';
  };
}
