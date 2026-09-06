{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = { pkgs, ... }: {
    imports = (with inputs.self.modules.homeManager; [
      # Shared modules
      shared-fish
      shared-git
      shared-neovim
      shared-fzf
      shared-zoxide
      shared-autojump
      shared-atuin
      shared-jq
      shared-tmux
      shared-tses
      shared-font
      shared-firefox
      shared-age

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
