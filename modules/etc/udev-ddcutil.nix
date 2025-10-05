{config, lib, pkgs, agenix, unstable, ... }:
{
  services.udev = {
    enable = true;
    extraRules =
    ''
# ddcui
SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
SUBSYSTEM=="dri", KERNEL=="card[0-9]*", TAG+="uaccess"
    '';
  };
}
