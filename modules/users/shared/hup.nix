{ ... }: {
  flake.modules.homeManager.shared-hup = { inputs, pkgs, ... }: {
    home.packages = [ inputs.huphop.packages."${pkgs.system}".default ];
  };
}
