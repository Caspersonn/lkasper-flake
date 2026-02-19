{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = {

    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      kde
    ]);

    nixpkgs.config.allowUnfree = true;

  };
}
