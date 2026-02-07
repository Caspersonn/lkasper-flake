{ inputs, ... }: {
  flake.modules.nixos.acme = { config, pkgs, ... }: {
    security.acme = {
      acceptTerms = true;
      defaults.email = "security@inspiravita.com";
    };
  };
}

