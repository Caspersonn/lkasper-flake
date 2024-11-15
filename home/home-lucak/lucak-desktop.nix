{config,pkgs,...}: {
 imports = [
  ./../_hm-modules
  ./lucak-common.nix
  ./../conf-gnome/gnome-settings.nix
];

}
