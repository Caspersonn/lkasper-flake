{ inputs, ... }: {
  flake.modules.nixos.technative = { pkgs, unstable, ... }: {
    environment.systemPackages = with pkgs; [
      lato
      inputs.mip-rs.packages."${pkgs.stdenv.hostPlatform.system}".default
      #inputs.nivis.packages."${pkgs.stdenv.hostPlatform.system}".nivis
      jira-cli-go
      unstable.jiratui
    ];

    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };
  };
}
