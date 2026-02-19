{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = {

    imports = (with inputs.self.modules.homeManager; [
      inputs.plasma-manager.homeModules.plasma-manager

      kde
      antonia-firefox
      antonia-zsh
      antonia-neovim
    ]);

    nixpkgs.config.allowUnfree = true;
  };
}
