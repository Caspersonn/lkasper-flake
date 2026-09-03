{ ... }: {
  flake.modules.homeManager.shared-tmux = { pkgs, lib, ... }:
    let
      rbwProfiles = {
        "work" = "TN";
      };

      rbwDefaultLabel = "LK";

      rbwCaseBody = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (profile: label: "    ${profile}) label=\"${label}\" ;;") rbwProfiles
      );

      rbwStatus = pkgs.writeShellScript "rbw-status" ''
        # Bron van waarheid: het bestand dat `rbwsel` schrijft. De status bar
        # draait in de tmux server, dus die heeft geen RBW_PROFILE uit een pane.
        profile="$(tr -d '\n' < "$HOME/.local/state/rbw-profile" 2>/dev/null || true)"
        profile="''${profile:-''${RBW_PROFILE:-}}"
        case "$profile" in
          ${rbwCaseBody}
          *) label="${rbwDefaultLabel}" ;;
        esac
        if RBW_PROFILE="$profile" rbw unlocked 2>/dev/null; then
          echo " $label"
        else
          echo " $label"
        fi
      '';
      in {
    programs.tmux = {
      enable = true;
      clock24 = false;
      plugins = [
        pkgs.tmuxPlugins.sensible
        pkgs.tmuxPlugins.yank
        pkgs.tmuxPlugins.tmux-fzf
      ];
      extraConfig = ''
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf
        bind C-x send-prefix
        set -g prefix C-x
        set -g mouse on

        source-file -q ~/.config/lkasper-hyprland/current/tmux.conf

        # Shortcuts
        bind S popup -E -w 80% -h 80% 'tses open'
        bind K popup -E -w 80% -h 80% 'tses kill'
        bind P popup -E -w 80% -h 80% 'tses pull'
        bind B popup -E -w 80% -h 80% 'beans tui'
        bind T popup -E -w 80% -h 80% 'tj --columns --sort-activity --no-sound --no-notify --picker'
        bind G popup -E -w 80% -h 80% 'drs ~/git'

        # Enable vi mode
        setw -g mode-keys vi

        # vim-like selection key bindings
        bind -T copy-mode-vi v send-keys -X begin-selection
        bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

        # set active-inactive window styles
        #set -g window-style 'fg=colour247,bg=colour236'
        #set -g window-active-style 'fg=default,bg=colour234'

        set -g status-right "#[fg=#a89984,bg=#282828] %Y-%m-%d  %H:%M #[fg=#3c3836,bg=#282828]#[fg=#ebdbb2,bg=#3c3836] #(${rbwStatus}) #[fg=#504945,bg=#3c3836]#[fg=#ebdbb2,bg=#504945] #h #[fg=#fe8019,bg=#504945]#[fg=#282828,bg=#fe8019] ⌨ #{prefix} "
        set -g @yank_selection_mouse 'clipboard'
        set -g @yank_with_mouse on
        set -gq allow-passthrough on
        set -g visual-activity off
      '';
    };

    home.packages = [ pkgs.tmux-sessionizer ];
  };
}
