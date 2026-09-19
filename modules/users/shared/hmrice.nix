{ inputs, ... }: {
  flake.modules.homeManager.shared-hmrice = { config, ... }: {
    imports = [
      inputs.hm-ricing-mode.homeManagerModules.hm-ricing-mode
    ];
    programs.hm-ricing-mode.enable = true;
  };
}
