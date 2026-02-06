{ inputs, ... }: {
  flake.modules.nixos.acme = { config, pkgs, ... }: {

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "security@inspiravita.com";
  };
}

