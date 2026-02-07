{ inputs, ... }: {
  flake.modules.nixos.acme = { config, pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      minica
      acme
      lego
    ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "acme@inspiravita.com";
    };
  };
}

