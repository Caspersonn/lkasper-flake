{ pkgs, ... }:
{
  programs.vesktop = {
    enable = true;
    settings = {
      hardwareAcceleration = true;
      discordBranch = "stable";
    };
    vencord ={
      settings = {
        autoUpdate = false;
        autoUpdateNotification = false;
        notifyAboutUpdates = false;
        useQuickCss = true;
        disableMinSize = true;
        enabledThemes = ["midnight-vencord.theme.css"];
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
          sha256 = "sha256-0n568grm4xhxn9laq3fzgkpa1nc9az18mnx3qfn6ca2jvjbhfgi9=";
        };
      };
    };
  };
}
