{config,pkgs,...}: {
 imports = [
  ./zsh.nix
   ./common.nix
  ./neovim.nix
  ./tmux.nix
  ./dotfiles/conf-default.nix
  # ./awsconf.nix
];

}
