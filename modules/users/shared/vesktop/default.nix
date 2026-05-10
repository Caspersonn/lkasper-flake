{ ... }: {
  flake.modules.homeManager.shared-vesktop = { pkgs, ... }: {
    programs.vesktop = {
      enable = true;
      settings = {
        hardwareAcceleration = true;
        discordBranch = "stable";
      };
      vencord = {
        settings = {
          autoUpdate = false;
          autoUpdateNotification = false;
          notifyAboutUpdates = false;
          useQuickCss = true;
          disableMinSize = true;
          enabledThemes = [ "midnight-vencord.theme.css" ];
          plugins = {
            MessageLogger = {
              enabled = true;
              ignoreSelf = true;
            };
            FakeNitro.enabled = true;
          };
        };
        themes = {
          # https://refact0r.github.io/midnight-discord/themes/flavors/midnight-vencord.theme.css
          midnight-vencord = pkgs.fetchurl {
            url = "https://refact0r.github.io/midnight-discord/themes/flavors/midnight-vencord.theme.css";
            sha256 = "sha256-KT4Hl9xSKGasw6PbisJXidmg7nzfDaxosh12UvNDplg=";
          };
        };
      };
    };
  };
}
