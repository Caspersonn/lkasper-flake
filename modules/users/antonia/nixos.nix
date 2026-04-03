{ inputs, self, ... }: {
  flake.modules.nixos.antonia = { pkgs, ... }: {
    users.users.antonia = {
      isNormalUser = true;
      description = "Antonia Gosker";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.zsh;
    };
  };
}
