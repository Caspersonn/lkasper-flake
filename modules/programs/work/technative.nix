{ inputs, unstable, ... }: {
  flake.modules.nixos.technative = { pkgs, ... }: {
    fonts.packages = with pkgs; [ lato ];

    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };
  };
}
