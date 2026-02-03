{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-classic;
  };
}
