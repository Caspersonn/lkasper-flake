{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = {

    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      inputs.plasma-manager.homeModules.plasma-manager
      kde
    ]);

    nixpkgs.config.allowUnfree = true;

  };
}
