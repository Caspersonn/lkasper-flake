{
  description = "Best config";

  inputs = {
    agenix.url = "github:ryantm/agenix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-2311.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-2405.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-2305.url = "github:NixOS/nixpkgs/nixos-23.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    bmc.url = "github:wearetechnative/bmc";
    race.url = "github:wearetechnative/race";
    jsonify-aws-dotfiles.url = "github:wearetechnative/jsonify-aws-dotfiles";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeage = {
      url = "github:jordanisaacs/homeage";
      # Optional
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };



  outputs = inputs@{ self, nixpkgs, nixpkgs-2305,  nixpkgs-2311, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixpkgs-2405, nixos-cosmic}: 
  let 
    system = "x86_64-linux";
    extraPkgs= {
      environment.systemPackages = [ 
        bmc.packages."${system}".bmc 
        race.packages."${system}".race 
        jsonify-aws-dotfiles.packages."${system}".jsonify-aws-dotfiles
      ];
    };
  in 
  {
  
# gaming-casper config START
  nixosConfigurations.gaming-casper = nixpkgs.lib.nixosSystem {
    modules =
      let
        system = "x86_64-linux";
        defaults = { pkgs, ... }: {
          nixpkgs.overlays = [(import ./overlays)];
          _module.args.unstable = import unstable { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2305 = import nixpkgs-2305 { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2311 = import nixpkgs-2311 { inherit system; config = {allowUnfree = true; }; };
          _module.args.agenix = inputs.agenix.packages."${system}".default;

        };

        

      in [
        defaults
        extraPkgs
        agenix.nixosModules.default
        ./hosts/gaming-casper/configuration.nix
        ./modules/desktop.nix
      ];
    };
# gaming-casper config END

# home-casper config START
  nixosConfigurations.home-casper = nixpkgs.lib.nixosSystem {
    modules =
      let
        system = "x86_64-linux";
        defaults = { pkgs, ... }: {
          nixpkgs.overlays = [(import ./overlays)];
          _module.args.unstable = import unstable { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2305 = import nixpkgs-2305 { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2311 = import nixpkgs-2311 { inherit system; config = {allowUnfree = true; }; };
          _module.args.agenix = inputs.agenix.packages."${system}".default;

        };

        

      in [
        defaults
        extraPkgs
        agenix.nixosModules.default
        ./hosts/home-casper/configuration.nix
        ./modules/desktop.nix
      ];
    };
# home-casper config END

# server-casper config START
  nixosConfigurations.server-casper = nixpkgs.lib.nixosSystem {
    modules =
      let
        system = "x86_64-linux";
        defaults = { pkgs, ... }: {
          nixpkgs.overlays = [(import ./overlays)];
          _module.args.unstable = import unstable { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2305 = import nixpkgs-2305 { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2311 = import nixpkgs-2311 { inherit system; config = {allowUnfree = true; }; };
          _module.args.agenix = inputs.agenix.packages."${system}".default;

        };

        

      in [
        defaults
        extraPkgs
        agenix.nixosModules.default
        ./hosts/server-casper/configuration.nix
        ./modules/desktop.nix
      ];
    };
# server-casper config END

# technative-lucak config START
  nixosConfigurations.technative-lucak = nixpkgs.lib.nixosSystem {
    modules =
      let
        system = "x86_64-linux";
        defaults = { pkgs, ... }: {
          nixpkgs.overlays = [(import ./overlays)];
          #_module.args.nixos-cosmic = import nixos-cosmic { inherit system; config = { substituters = ["https://cosmic.cachix.org/"]; trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ]; }; };
          _module.args.unstable = import unstable { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2305 = import nixpkgs-2305 { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2311 = import nixpkgs-2311 { inherit system; config = {allowUnfree = true; }; };
          _module.args.agenix = inputs.agenix.packages."${system}".default;

        };

        

      in [
        #nixos-cosmic.nixosModules.default
        defaults
        extraPkgs
        agenix.nixosModules.default
        ./hosts/technative-lucak/configuration.nix
        ./modules/desktop.nix
      ];
    };
# technative-casper config END

## home-manager config

# gaming-casper home-manager START
  # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
  homeConfigurations."gaming-casper@linuxdesktop" = home-manager.lib.homeManagerConfiguration(
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      linux-defaults = {pkgs,config,homeage,...}: {
        home = { ##MAC
        homeDirectory = "/home/casper";
      };
    };

    in {
      inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.

        modules = [
         ./home/casper-desktop.nix
         #./home/dotfiles/conf-default.nix
         linux-defaults
       ];
     });
# gaming-casper home-manager END

# home-casper home-manager START
  # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
  homeConfigurations."home-casper@linuxdesktop" = home-manager.lib.homeManagerConfiguration(
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      linux-defaults = {pkgs,config,homeage,...}: {
        home = { ##MAC
        homeDirectory = "/home/casper";
      };
    };

    in {
      inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.

        modules = [
         ./home/casper-desktop.nix
         #./home/dotfiles/conf-default.nix
         linux-defaults
       ];
     });
# home-casper home-manager END

# server-casper home-manager START
  # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
  homeConfigurations."server-casper@linuxdesktop" = home-manager.lib.homeManagerConfiguration(
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      linux-defaults = {pkgs,config,homeage,...}: {
        home = { ##MAC
        homeDirectory = "/home/casper";
      };
    };

    in {
      inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.

        modules = [
         ./home/casper-desktop.nix
         linux-defaults
       ];
     });
# server-casper home-manager END

# technative-lucak home-manager START
  # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
  homeConfigurations."technative-lucak@linuxdesktop" = home-manager.lib.homeManagerConfiguration(
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      linux-defaults = {pkgs,config,homeage,...}: {
        home = { ##MAC
        homeDirectory = "/home/lucak";
      };
    };

    in {
      inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.

        modules = [
         ./home/lucak-desktop.nix
         #./home/dotfiles/conf-default.nix
         linux-defaults
       ];
     });
# technative-lucak home-manager END
};
}
