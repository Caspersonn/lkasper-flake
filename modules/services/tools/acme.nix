{ inputs, ... }: {
  flake.modules.nixos.acme = { config, pkgs, ... }: {
    security.acme = {
      enable = true;
      acceptTerms = true;
      defaults.email = "security@inspiravita.com";
    };
  };
}

