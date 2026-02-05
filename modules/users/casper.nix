{ inputs, ... }: {
  flake.modules.nixos.casper = { config, pkgs, ... }: {
    # User account for casper
    users.users.casper = {
      isNormalUser = true;
      description = "Luca Kasper";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr"
      ];
    };
    users.defaultUserShell = pkgs.zsh;
    programs.zsh.enable = true;
  };
}
