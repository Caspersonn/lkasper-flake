{ ... }: {
  flake.modules.homeManager.casper-dirtygit = { inputs, pkgs, ... }: {
    home.packages = [ inputs.dirtygit.packages."${pkgs.system}".dirtygit ];

    home.file = { "./.dirtygit.yml" = { source = ./dirtygit.yml; }; };
  };
}
