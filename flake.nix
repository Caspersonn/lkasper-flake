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



  outputs = inputs@{ self, nixpkgs, nixpkgs-2305,  nixpkgs-2311, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixpkgs-2405}: 
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
  
 # Casper config START
  nixosConfigurations.casper = nixpkgs.lib.nixosSystem {
    modules =
      let
        system = "x86_64-linux";
        defaults = { pkgs, ... }: {
        # nixpkgs.overlays = [(import ./overlays)];
          _module.args.unstable = import unstable { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2305 = import nixpkgs-2305 { inherit system; config = {allowUnfree = true; }; };
          _module.args.pkgs-2311 = import nixpkgs-2311 { inherit system; config = {allowUnfree = true; }; };
          _module.args.agenix = inputs.agenix.packages."${system}".default;

        };

        

      in [
        defaults
        extraPkgs
        agenix.nixosModules.default
        ./hosts/casper/configuration.nix
        #./modules/tnaws.nix
        ./modules/casper-desktop.nix
      ];
    };
# casper config END


 # LINUX HOMEMANAGER START LKASPER
  # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
  homeConfigurations."casper@linuxdesktop" = home-manager.lib.homeManagerConfiguration(
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
         #./home/default.nix
         ./home/linux-desktop.nix
         ./home/firefox.nix
         #./home/dotfiles/toggl-secret-wtoorren.nix
         linux-defaults
       ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      });
  ### LINUX HOMEMANAGER END LKASPER
};
}
