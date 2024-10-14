{config,pkgs,...}: {
 imports = [
  ./zsh.nix
 # ./awsconf.nix
  ./common.nix
  ./neovim.nix
  ./tmux.nix
#  ./dotfiles/toggl-secret.nix
];

}
