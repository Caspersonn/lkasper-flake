{ inputs, ... }: {
  flake.modules.nixos.casper = { config, pkgs, ... }: {
    # User account for casper
    users.users.casper = {
      isNormalUser = true;
      description = "Luca Kasper";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.zsh;
    };
    users.defaultUserShell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
