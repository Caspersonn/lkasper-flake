{ inputs, ... }: {
  flake.modules.nixos.disk-utils = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      libffi
      libffi_3_3
      polkit_gnome
      gnome-disk-utility
      gparted
    ];
  };
}
