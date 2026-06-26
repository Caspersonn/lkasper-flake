{ inputs, unstable, ... }: {
  flake.modules.nixos.technative = { pkgs, ... }: {
    fonts.packages = with pkgs; [ 
      lato
      inputs.mip-rs.packages."${pkgs.stdenv.hostPlatform.system}".default
      inputs.nivis.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };
  };
}
