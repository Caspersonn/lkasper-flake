{config,pkgs,...}: {
 imports = [
  ./../_hm-modules/programs/zsh.nix
  ./../_hm-modules/programs/neovim.nix
  ./../_hm-modules/programs/tmux.nix
  ./lucak-common.nix
  ./../conf-gnome/gnome-settings.nix
];

}