{config,pkgs,...}: {
 imports = [
  ./../zsh.nix
  ./casper-common.nix
  ./../neovim.nix
  ./../tmux.nix
  ./../.dotfiles/conf-default.nix
];

}
