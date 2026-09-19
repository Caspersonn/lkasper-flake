{ inputs, ... }: {
  flake.modules.nixos.technative = { pkgs, unstable, ... }: {
    environment.systemPackages = with pkgs; [
      lato
      inputs.mip-rs.packages."${pkgs.system}".default
      #inputs.nivis.packages."${pkgs.system}".nivis
      jira-cli-go
      unstable.jiratui
    ];

    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };
  };
}
