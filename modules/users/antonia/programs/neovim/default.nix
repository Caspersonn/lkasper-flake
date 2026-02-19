{ ... }: {
  flake.modules.homeManager.antonia-neovim = { inputs, pkgs, ... }: {
    home.packages = [ inputs.nixvim.packages.x86_64-linux.default ];

    home.sessionVariables.EDITOR = "nvim";
  };
}
