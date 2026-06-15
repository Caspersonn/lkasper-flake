{ inputs, self, lib, ... }: {
  flake.lib.makeNixos = { hostname, system ? "x86_64-linux", username ? "casper"
    , channel ? inputs.nixpkgs, enableFrameworkHardware ? true, ... }:
    channel.lib.nixosSystem {
      modules = let
        defaults = { pkgs, ... }: {
          _module.args.inputs = inputs;
          _module.args.unstable = import inputs.unstable {
            inherit system;
            config.allowUnfree = true;
          };
          nixpkgs.hostPlatform = system;
          nixpkgs.config.allowUnfree = true;
        };
      in [
        defaults
        inputs.self.modules.nixos.${hostname}
      ];
    };

  flake.lib = {
    makeHomeConf = {
      nixpkgs-channel ? inputs.nixpkgs,
      username ? "casper",
      hostname,
      imports ? [],
      homedir ? "/home/casper",
      system ? "x86_64-linux",
      ...
      }:
      inputs.home-manager.lib.homeManagerConfiguration {

        modules = [
          {
            home.stateVersion = "26.05";
            home.username = username;
            home.homeDirectory = homedir;
          }

          ({ lib, ... }: {
            _module.args.osConfig = lib.mkForce {
              services.xserver.videoDrivers = [];
            };
          })
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
