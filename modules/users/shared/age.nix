{ inputs, ... }: {
  flake.modules.homeManager.shared-age = { config, ... }: {
    imports = [
        inputs.agenix.homeManagerModules.default
    ];
  };
}
