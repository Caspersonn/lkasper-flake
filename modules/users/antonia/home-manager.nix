{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = { pkgs, ... }: {
    imports = (with inputs.self.modules.homeManager; [
      # Shared modules
      shared-age
      shared-atuin
      shared-autojump
      shared-firefox
      shared-fish
      shared-font
      shared-fzf
      shared-git
      shared-hmrice
      shared-jq
      shared-neovim
      shared-tmux
      shared-tses
      shared-zoxide

      # Personal Modules
      antonia-gnome
    ]);

    # Git identity
    programs.git.settings.user = {
      email = "antoniagosker@gmail.com";
      name = "antonia";
    };

    # Personal Firefox profile
    programs.firefox.profiles.personal = {
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
        "sidebar.verticalTabs" = false;
      };
    };
  };
}
