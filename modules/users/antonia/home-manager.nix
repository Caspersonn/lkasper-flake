{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = { pkgs, ... }: {
    imports = (with inputs.self.modules.homeManager; [
      gnome
      antonia-firefox
      antonia-zsh
      antonia-neovim
      antonia-git
    ]);

    nixpkgs.config.allowUnfree = true;
  };
}
