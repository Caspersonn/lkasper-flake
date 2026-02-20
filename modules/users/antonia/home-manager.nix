{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = {

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
