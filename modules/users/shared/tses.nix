{ ... }: {
  flake.modules.homeManager.shared-tses = { inputs, pkgs, ... }: {
    home.packages = [ inputs.tses.packages."${pkgs.system}".default inputs.huphop.packages."${pkgs.system}".default ];
  };
}
