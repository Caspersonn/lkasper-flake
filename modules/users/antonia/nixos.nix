{ inputs, self, ... }: {
  flake.modules.nixos.antonia = { pkgs, ... }: {
    imports = [ inputs.agenix.nixosModules.default ];

    age.secrets.atuin-antonia-session = {
      file = ../../../secrets/atuin-antonia-session.age;
      owner = "antonia";
      mode = "0400";
    };
    age.secrets.atuin-antonia-key = {
      file = ../../../secrets/atuin-antonia-key.age;
      owner = "antonia";
      mode = "0400";
    };

    users.users.antonia = {
      isNormalUser = true;
      description = "Antonia Gosker";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.fish;
    };

    programs.fish.enable = true;
  };
}
