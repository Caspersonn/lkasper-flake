{config,pkgs,...}: {
 imports = [
  ./zsh.nix
  ./common.nix
  ./neovim.nix
  ./tmux.nix
];

}

