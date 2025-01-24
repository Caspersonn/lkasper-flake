{
  description = "Best config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    bmc.url = "github:wearetechnative/bmc";
    race.url = "github:wearetechnative/race";
    jsonify-aws-dotfiles.url = "github:wearetechnative/jsonify-aws-dotfiles";

    # Cosmic from pop-os
    nixpkgs.follows = "nixos-cosmic/nixpkgs"; # NOTE: change "nixpkgs" to "nixpkgs-stable" to use stable NixOS release
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeage = {
      url = "github:jordanisaacs/homeage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixos-cosmic }: 

  let 
    importFromChannelForSystem = system: channel: import channel {
      overlays = [
        (import ./overlays)
      ];
      inherit system;
      config.allowUnfree = true;
    };

    makeHomeConf = {
    username ? "casper",
    hostname,
    homedir ? "/home/casper",
    system ? "x86_64-linux",
    ...
  }:    
  home-manager.lib.homeManagerConfiguration {
    modules = [
      (import ./home/casper)
      {
        home.stateVersion = "24.11";
        home.username = username;
        home.homeDirectory = homedir;
      }
    ];
    pkgs = importFromChannelForSystem system nixpkgs;
    extraSpecialArgs = {
      system = system;
      inputs = inputs;
      unstable = importFromChannelForSystem system unstable;
    };
  };
  
  makeNixosConf = {
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
    ...
    }: 
    nixpkgs.lib.nixosSystem {
      modules = 
        let
          defaults = { pkgs, ... }: {
            nixpkgs.overlays = [(import ./overlays)];
            _module.args.unstable = importFromChannelForSystem system unstable;
          };

          extraPkgs = {
            environment.systemPackages = [
              agenix.packages."${system}".agenix
              race.packages."${system}".race
              bmc.packages."${system}".bmc
              jsonify-aws-dotfiles.packages."${system}".jsonify-aws-dotfiles
            ];
          };
          cosmic = {
            nix.settings = {
              substituters = [ "https://cosmic.cachix.org/" ];
              trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
            };
          };

        in [
            defaults
            #nixos-hardware.nixosModules.framework-12th-gen-intel
            (./hosts + "/${hostname}/configuration.nix")

            agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
            }
            cosmic
            extraPkgs

          ] ++
        extraModules;
    };

  in
    rec {
      
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-classic;

    ########################
    ## HomeManager config ##
    ########################

    homeConfigurations."technative-lucak@linuxdesktop" = makeHomeConf {
        system = "x86_64-linux";
        hostname = "technative-lucak";
        username = "lucak";
        homedir = "/home/lucak";
    };

    homeConfigurations."gaming-casper@linuxdesktop" = makeHomeConf {
        system = "x86_64-linux";
        hostname = "gaming-casper";
    };

    homeConfigurations."server-casper@linuxdesktop" = makeHomeConf {
        system = "x86_64-linux";
        hostname = "server-casper";
    };

    homeConfigurations."home-casper@linuxdesktop" = makeHomeConf {
        system = "x86_64-linux";
        hostname = "home-casper";
    };

    ##################
    ## NixOs config ##
    ##################

    nixosConfigurations.technative-lucak = makeNixosConf {
      hostname = "technative-lucak";
      extraModules = [ nixos-cosmic.nixosModules.default ];
    };
    nixosConfigurations.gaming-casper = makeNixosConf {
      hostname = "gaming-casper";
    };
    nixosConfigurations.server-casper = makeNixosConf {
      hostname = "server-casper";
    };
    nixosConfigurations.home-casper = makeNixosConf {
      hostname = "home-casper";
    };
  };
}
