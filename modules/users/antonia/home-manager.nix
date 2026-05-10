{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = { pkgs, ... }: {
    imports = (with inputs.self.modules.homeManager; [
      # Shared modules
      shared-zsh
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

      # Antonia desktop
      gnome
    ]);

    # Git identity
    programs.git.settings.user = {
      email = "antoniagosker@gmail.com";
      name = "antonia";
    };
    programs.git.settings.push.default = "simple";
    programs.git.settings.branch.autosetupmerge = true;

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

    nixpkgs.config.allowUnfree = true;
  };
}
