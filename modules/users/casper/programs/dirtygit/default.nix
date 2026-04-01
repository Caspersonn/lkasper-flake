{ ... }: {
  flake.modules.homeManager.casper-dirtygit = { inputs, pkgs, ... }: {
    home.packages = [ inputs.dirty-repo-scanner.packages."${pkgs.system}".dirty-repo-scanner ];

    home.file = { "./.dirtygit.yml" = { source = ./dirtygit.yml; }; };
  };
}
