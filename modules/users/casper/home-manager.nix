{ inputs, self, ... }: {
  flake.modules.homeManager.casper = { pkgs, config, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      # Omarchy-nix (Hyprland desktop)
      lkh-ags
      lkh-btop
      lkh-direnv
      lkh-fonts
      lkh-foot
      lkh-ghostty
      lkh-hypridle
      lkh-hyprland
      lkh-hyprlock
      lkh-hyprpaper
      lkh-hyprshot
      lkh-themes
      lkh-walker
      lkh-yazi
      lkh-zoxide

      # Shared modules
      shared-age
      shared-atuin
      shared-autojump
      shared-aws
      shared-aws
      shared-claude
      shared-dirty-repo-scanner
      shared-firefox
      shared-fish
      shared-font
      shared-fzf
      shared-git
      shared-hup
      shared-jq
      shared-jujutsu
      shared-meridian
      shared-neovim
      shared-opencode
      shared-ragenx
      shared-rbw
      shared-scripts
      shared-smug
      shared-technative
      shared-tmux
      shared-tses
      shared-vesktop
      shared-zoxide
    ]);

    # Git identity
    programs.git.settings.user = {
      email = "lucakasper8@gmail.com";
      name = "Caspersonn";
    };

    programs.jujutsu.settings.user = {
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

    programs.firefox.profiles.personal = {
      id = 0;
      name = "personal";
      isDefault = true;
      search.default = "kg";
      search.force = true;
      search.engines = {
        kagi = {
          name = "Kagi";
          urls = [
            {
              template = "https://www.kagi.com";
              params = [ { name = "search"; value = "{searchTerms}"; } ];
            }
          ];
          definedAliases = [ "@kg" ];
        };
        "Nix Packages" = {
          urls = [
            {
              template = "https://search.nixos.org/packages";
              params = [
                { name = "channel"; value = "unstable"; }
                { name = "query";   value = "{searchTerms}"; }
              ];
            }
          ];
          icon           = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = [ "@np" ];
        };
      };
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
  };
}
