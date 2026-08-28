{ inputs, ... }: {
  flake.modules.nixos.kdeconnect = { pkgs, ... }: {
    programs.kdeconnect.enable = true;
  };
}
