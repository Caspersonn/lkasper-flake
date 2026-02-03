{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    # Formatter for 'nix fmt'
    formatter = pkgs.nixfmt-classic;
  };
}
