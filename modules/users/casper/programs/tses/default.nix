{ ... }: {
  flake.modules.homeManager.casper-tses = { inputs, pkgs, ... }: {
    home.packages = [ inputs.tses.packages."${pkgs.system}".default ];
  };
}
