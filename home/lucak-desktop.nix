{config,pkgs,...}: {
 imports = [
  ./zsh.nix
  ./lucak-common.nix
  ./neovim.nix
  ./tmux.nix
  ./dotfiles/conf-default.nix
];

}
