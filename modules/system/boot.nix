{ inputs, ... }: {
  flake.modules.nixos.boot = { config, pkgs, ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
