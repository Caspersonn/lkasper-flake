{ ... }: {
  flake.modules.homeManager.shared-tmux = { pkgs, ... }: {
    programs.tmux = {
      enable = true;
      clock24 = false;
      plugins = [
        pkgs.tmuxPlugins.gruvbox
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

        # Tmux theming
        set -g @tmux-gruvbox 'dark' # or 'dark256', 'light', 'light256'
        set -g @tmux-gruvbox-statusbar-alpha 'true'

        # Shortcuts
        bind S popup -E 'tses open'
        bind K popup -E 'tses kill'
        bind P popup -E 'tses pull'
        bind T popup -E -w 80% -h 80% 'tj --columns --sort-activity --no-sound --no-notify --picker'

        set -g @yank_selection_mouse 'clipboard'
        set -g @yank_with_mouse on
        set -gq allow-passthrough on
        set -g visual-activity off
      '';
    };

    home.packages = [ pkgs.tmux-sessionizer ];
  };
}
