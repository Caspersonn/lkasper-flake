{config, pkgs, lib, ...}: 

{
  programs.librewolf = {
    enable = true;
    settings = {
    # Add-ons and behavior
    "webgl.disabled" = false;
    "privacy.resistFingerprinting" = false;

    # Cookie behavior
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.history" = false;
    "network.cookie.lifetimePolicy" = 0;

    # UI tweaks
    "browser.toolbars.bookmarks.visibility" = "never";
    "browser.bookmarks.addedImportButton" = false;
  };
};
}
