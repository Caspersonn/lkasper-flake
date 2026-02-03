{ inputs, lib, ... }:
let
  inherit (inputs)
    nixpkgs nixpkgs2405 unstable home-manager agenix nixos-hardware monitoring
    bmc race jsonify-aws-dotfiles openspec spicetify-nix walker;

  # Import helper from overlays module
  importFromChannelForSystem = inputs.self.lib.importFromChannelForSystem;

  makeNixosConf = { hostname, system ? "x86_64-linux", username ? "casper"
    , enableFrameworkHardware ? true, ... }:
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs username hostname; };
      modules = let
        defaults = { pkgs, ... }: {
          nixpkgs.overlays = [ (import ../overlays) ];
          _module.args.unstable = importFromChannelForSystem system unstable;
          _module.args.pkgs2405 = importFromChannelForSystem system nixpkgs2405;
        };

        extraPkgs = {
          environment.systemPackages = [
            agenix.packages."${system}".agenix
            race.packages."${system}".race
            bmc.packages."${system}".bmc
            walker.packages."${system}".walker
            jsonify-aws-dotfiles.packages."${system}".jsonify-aws-dotfiles
            openspec.packages."${system}".default
          ];
        };

        frameworkHardware = nixpkgs.lib.optionals enableFrameworkHardware
          [ nixos-hardware.nixosModules.framework-13-7040-amd ];
      in [
        defaults
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
        monitoring.nixosModules.monitoring
        spicetify-nix.nixosModules.spicetify
        extraPkgs
        {
          home-manager.useGlobalPkgs = true;
        }
        # Use dendritic host module
        inputs.self.modules.nixos.${hostname}
      ] ++ frameworkHardware;
    };
in {
  flake.nixosConfigurations = {
    technative-casper = makeNixosConf { hostname = "technative-casper"; };

    gaming-casper = makeNixosConf { hostname = "gaming-casper"; };

    server-casper = makeNixosConf {
      hostname = "server-casper";
      system = "aarch64-linux";
      enableFrameworkHardware = false;
    };

    personal-casper = makeNixosConf { hostname = "personal-casper"; };
  };
}
