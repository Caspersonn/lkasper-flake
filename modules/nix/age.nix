{ inputs, ... } : {
  flake.modules.nixos.age = { pkgs, ... }: {

    environment.systemPackages = [
      inputs.agenix.packages."${pkgs.system}".default
    ];

    imports = [
      inputs.agenix.nixosModules.default
    ];
  };
}
