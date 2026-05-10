{ inputs, self, ... }: {
  flake.modules.nixos.lucak = { pkgs, ... }: {
    users.users.lucak = {
      isNormalUser = true;
      description = "Luca Kasper (werk)";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr"
      ];
    };
  };
}
