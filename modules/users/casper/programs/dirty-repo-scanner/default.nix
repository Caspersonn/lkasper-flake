{ ... }: {
  flake.modules.homeManager.casper-dirty-repo-scanner = { inputs, pkgs, ... }: {
    home.packages = [ inputs.dirty-repo-scanner.packages."${pkgs.system}".dirty-repo-scanner ];

    home.file = { "./.config/dirty-repo-scanner/config.yml" = { source = ./config.yml; }; };
  };
}
