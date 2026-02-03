{ inputs, ... }: {
  flake.modules.nixos.cosmic = { config, ... }: {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    services.flatpak.enable = true;

    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

    nix.settings = {
      substituters = [ "https://cosmic.cachix.org/" ];
      trusted-public-keys =
        [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
    };
  };
}
