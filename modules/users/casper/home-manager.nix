{ inputs, self, ... }: {
  flake.modules.homeManager.casper = { pkgs, config, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      # Omarchy-nix (Hyprland desktop)
      lkh-themes
      lkh-ags
      lkh-hyprland
      lkh-ghostty
      lkh-hyprlock
      lkh-hyprpaper
      lkh-hypridle
      lkh-btop
      lkh-zsh
      lkh-starship
      lkh-direnv
      lkh-fonts
      lkh-zoxide
      lkh-hyprshot
      lkh-walker
      lkh-mako

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
      shared-opencode
      shared-dirty-repo-scanner
      shared-smug
      shared-vesktop

      # Work shared modules
      shared-technative

      # Lucak-only complex modules
      lucak-aws
    ]);

    # Git identity
    programs.git.settings.user = {
      email = "lucakasper8@gmail.com";
      name = "Caspersonn";
    };

    # Personal zsh aliases
    programs.zsh.shellAliases = {
      tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
      tfswitch = "mkdir -p ~/bin ; tfswitch -b $HOME/bin/terraform";
      tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
      tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
      aws-switch = ". bmc profsel";
      aws-mfa = "$HOME/lkasper-flake/modules/_unused/casper-hyprland-legacy/scripts/aws-mfa-auto.sh";
      bcd =
        "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude";
      bcdc =
        "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude -c";
      lin = "vi -c LinnyMenuOpen";
      ner = "vi -c Neotree";
      runbg = "$HOME/.config/hypr/scripts/runbg.sh";
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
        "sidebar.verticalTabs" = true;
        "browser.startup.homepage" = "https://search.nixos.org";
        "browser.startup.page" = 3;
        "browser.newtabpage.pinned" = [
          {
            title = "YouTube";
            url = "https://youtube.com";
          }
          {
            title = "Gmail";
            url = "https://gmail.com";
          }
        ];
      };
    };

    # Librewolf (disabled, personal only)
    programs.librewolf = {
      enable = false;
      package = pkgs.librewolf;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
