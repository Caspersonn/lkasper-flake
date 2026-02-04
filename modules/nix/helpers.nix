{ inputs, self, lib, ... }: {
  flake.lib.makeNixos = { hostname, system ? "x86_64-linux", username ? "casper"
    , channel ? inputs.nixpkgs, enableFrameworkHardware ? true, ... }:
    channel.lib.nixosSystem {
      modules = let
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

  #flake.lib.makeHomeConf = { username ? "casper", hostname
  #  , system ? "x86_64-linux", channel ? inputs.nixpkgs, imports ? [ ], ... }:
  #  inputs.home-manager.lib.homeManagerConfiguration {
  #    pkgs = import channel {
  #      inherit system;
  #      config.allowUnfree = true;
  #    };
  #    extraSpecialArgs = {
  #      inherit inputs hostname username;
  #      unstable = import inputs.unstable {
  #        inherit system;
  #        config.allowUnfree = true;
  #      };
  #    };
  #    modules = [{
  #      home = {
  #        inherit username;
  #        homeDirectory = "/home/${username}";
  #        stateVersion = "25.11";
  #      };
  #      programs.home-manager.enable = true;
  #    }] ++ imports;
  #  };

  flake.lib = {
    makeHomeConf = {
      nixpkgs-channel ? inputs.nixpkgs,
      username ? "casper",
      hostname,
      imports ? [],
      homedir ? "/home/casper",
      system ? "x86_64-linux",
      #secondbrain ? false,
      #awscontrol ? false,
      #desktop ? false,
      #swapAltWin ? false,
      ...
      }:
      inputs.home-manager.lib.homeManagerConfiguration {

        modules = [

          #inputs.self.modules.homeManager.${username}

          #inputs.hm-ricing-mode.homeManagerModules.hm-ricing-mode

          #(inputs.import-tree ../../home/_generic-for-contribution)
          #(../../home + "/${username}")

          {
            home.stateVersion = "25.11";
            home.username = username;
            home.homeDirectory = homedir;
          }
        ] ++ imports;

        pkgs = import nixpkgs-channel {
          inherit system;
          #overlays = [ (import ../overlays) ];
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit inputs system;
          unstable = import inputs.unstable {
            inherit system;
            #overlays = [ (import ../overlays) ];
            config.allowUnfree = true;
          };
        };
      };
  };
}
