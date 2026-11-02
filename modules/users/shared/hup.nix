{ ... }: {
  flake.modules.homeManager.shared-hip = { inputs, pkgs, ... }: {
    home.packages = [ inputs.hip.packages."${pkgs.system}".default ];
  };
}
