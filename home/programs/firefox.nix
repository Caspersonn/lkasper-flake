{ pkgs, ...}:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    policies.ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpl";
        installation_mode = "force_installed";
      };
      "aws-extend-switch-roles@toshi.tilfin.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/aws-extend-switch-roles3/latest.xpl";
        installation_mode = "force_installed";
      };
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpl";
        installation_mode = "force_installed";
      };
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpl";
        installation_mode = "force_installed";
      };
      "{b5e0e8de-ebfe-4306-9528-bcc18241a490}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/granted/latest.xpl";
        installation_mode = "force_installed";
      };
    };
    profiles = {
      personal = {
        id = 0;
        name = "personal";
        isDefault = true;
        search.default = "ddg";
        settings = {
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.bookmarks.addedImportButton" = false;
          "webgl.disabled" = false;
          "privacy.resistFingerprinting" = false;
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "network.cookie.lifetimePolicy" = "0";
          "sidebar.verticalTabs" = true;

          "browser.startup.homepage" = "https://search.nixos.org";
          "browser.startup.page" = 3;
          "browser.newtabpage.pinned" = [{
            title = "YouTube";
            url = "https://youtube.com";
          }
          {
            title = "Gmail";
            url = "https://gmail.com";
          }];
        };
      };
      work = {
        id = 1;
        name = "work";
        isDefault = false;
        search.default = "ddg";
        settings = {
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.bookmarks.addedImportButton" = false;
          "webgl.disabled" = false;
          "privacy.resistFingerprinting" = false;
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "network.cookie.lifetimePolicy" = "0";
          "sidebar.verticalTabs" = true;

          "browser.startup.homepage" = "https://search.nixos.org";
          "browser.startup.page" = 3;
          "browser.newtabpage.pinned" = [{
            title = "YouTube";
            url = "https://youtube.com";
          }
          {
            title = "Outlook";
            url = "https://outlook.com";
          }];
        };
      };
    };
  };
}
