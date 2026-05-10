{ ... }: {
  flake.modules.homeManager.casper-kitty = { ... }: {
    programs.kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
      themeFile = "GruvboxMaterialDarkHard";
      settings = { background_opacity = 0.9; };
    };
  };
}
