{ inputs, ... }: {
  flake.modules.nixos.acme = { config, pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      acme
      lego
    ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "security@inspiravita.com";
    };
  };
}

