{ inputs, ... }: {
  flake.modules.homeManager.casper-age = { config, ... }: {
    imports = [
        inputs.agenix.homeManagerModules.default
    ];
  };
}
