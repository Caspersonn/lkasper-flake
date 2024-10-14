{config, pkgs, ...}

tmux = {
	enable = true;
	clock24 = true;
	extraConfig = ''
unbind r
bind r source-file ~/.config/tmux/tmux.conf
set -g prefix C-x
set -g mouse on
set -g @plugin 'tmux-plugins/tpm
set -g @plugin 'tmux-plugins/tmux-sensible
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @yank_selection_mouse 'clipboard'
set -g @yank_with_mouse on
run '~/.config/tmux/plugins/tpm/tpm' #keep this line at the bottom!	
	''
	;
};

