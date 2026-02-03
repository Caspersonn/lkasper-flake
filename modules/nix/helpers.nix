{ inputs, ... }: {
  flake.lib.makeNixos = {
    hostname,
    system ? "x86_64-linux",
    username ? "casper",
    channel ? inputs.nixpkgs,
    enableFrameworkHardware ? true,
    ...
    }:
    channel.lib.nixosSystem {
      modules = 
        let
          defaults = { pkgs, ... }: {
            _module.args.inputs = inputs;
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
          };
        in [
            defaults
            #  home-manager.nixosModules.home-manager
            #  agenix.nixosModules.default
            #  monitoring.nixosModules.monitoring
            #  spicetify-nix.nixosModules.spicetify
          #{ home-manager.useGlobalPkgs = true; }
            inputs.self.modules.nixos.${hostname}
          ];
    };
}
