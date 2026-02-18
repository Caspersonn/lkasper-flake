{pkgs, ...}:

{
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
      set -g @plugin 'tmux-plugins/tpm
      set -g @plugin 'tmux-plugins/tmux-sensible
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'sainnhe/tmux-fzf'

      # Tmux theming
      set -g @plugin 'tmux-plugins/tmux-sensible' # optional recommended
      set -g @plugin 'egel/tmux-gruvbox'
      set -g @tmux-gruvbox 'dark' # or 'dark256', 'light', 'light256'
      set -g @tmux-gruvbox-statusbar-alpha 'true'

      set -g @yank_selection_mouse 'clipboard'
      set -g @yank_with_mouse on
      set -gq allow-passthrough on
      set -g visual-activity off
      run '~/.config/tmux/plugins/tpm/tpm' #keep this line at the bottom!
    ''
    ;
  };

  home.packages = [
    pkgs.tmux-sessionizer
  ];
}
