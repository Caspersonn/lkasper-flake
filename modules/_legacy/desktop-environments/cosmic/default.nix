{inputs, config, ...}:
{
  imports = [
    ./desktop-cosmic.nix
    inputs.nixos-cosmic.nixosModules.default
  ];
}

