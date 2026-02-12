{ inputs, ... }: {
  flake.modules.nixos.hm-users = { config, pkgs, ... }: {
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

    nix.settings.require-sigs = false;
    nix.settings.trusted-public-keys = ["gaming-casper:KYvnn1Wx4w2rbz7dQQHUvHu+0N5NxsDlLkSpIX3WGeM="];
  };
}
