{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt;
  };
}
