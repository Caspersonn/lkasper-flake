{
  description = "Best config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    bmc.url = "github:wearetechnative/bmc";
    race.url = "github:wearetechnative/race";
    jsonify-aws-dotfiles.url = "github:wearetechnative/jsonify-aws-dotfiles";
    croctalk.url = "github:wearetechnative/croctalk";
    nixpkgs-cosmic.follows = "nixos-cosmic/nixpkgs";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    stylix.url = "github:danth/stylix/release-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homeage = {
      url = "github:jordanisaacs/homeage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixtendo-switch = {
      url = "github:nyawox/nixtendo-switch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixtendo-switch, croctalk, nixpkgs-cosmic, nixos-cosmic, stylix }:


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
    desktop ? true,
    ...
  }:    
  home-manager.lib.homeManagerConfiguration {
    modules = [
      stylix.homeManagerModules.stylix
      (import ./home)
      {
        home.stateVersion = "24.11";
        home.username = username;
        home.homeDirectory = homedir;
        roles.desktop.enable = desktop;
      }
    ];
    pkgs = importFromChannelForSystem system nixpkgs;
    extraSpecialArgs = {
      system = system;
      inputs = inputs;
      hostname = hostname;
      username = username;
      unstable = importFromChannelForSystem system unstable;
    };
  };

  makeNixosConf = {
    hostname,
    system       ? "x86_64-linux",
    extraModules ? [],
    username     ? "casper",
    gnome        ? true,
    hyprland     ? false,
    cosmic       ? false,
    kde          ? false,
    ...
    }: 
    let 
      lib = nixpkgs.lib;
      desktopModules =
        lib.optionals gnome [ ./modules/desktop-environments/gnome ] ++
        lib.optionals hyprland [ ./modules/desktop-environments/hyprland ] ++
        lib.optionals cosmic [ ./modules/desktop-environments/cosmic ] ++
        lib.optionals kde [ ./modules/desktop-environments/kde ];
    in
    nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs username hostname;
        roles = {
          inherit gnome hyprland cosmic kde;
        };
      };
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
              croctalk.packages."${system}".croctalk
            ];
          };
        in [
            defaults
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
              home-manager.useGlobalPkgs = true;
            }
            extraPkgs 
          ] ++ desktopModules ++ extraModules;
    };

  in
    rec {
      
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-classic;

    ########################
    ## HomeManager config ##
    ########################

    homeConfigurations."technative-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "technative-casper";
        username = "lucak";
        homedir  = "/home/casper";
    };

    # TODO: Change name to casper
    #homeConfigurations."technative-server@linuxdesktop" = makeHomeConf {
    #    system   = "x86_64-linux";
    #    hostname = "technative-lucak";
    #    username = "lucak";
    #    homedir  = "/home/lucak";
    #    desktop  = false;
    #};

    # TODO: Change name to casper
    #homeConfigurations."dreammachine-luca@linuxdesktop" = makeHomeConf {
    #    system   = "x86_64-linux";
    #    hostname = "server-casper";
    #    username = "luca";
    #    homedir  = "/home/luca";
    #    desktop  = false;
    #};

    homeConfigurations."gaming-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "gaming-casper";
        desktop  = true;
    };

    homeConfigurations."server-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "server-casper";
        desktop  = false;
    };

    homeConfigurations."home-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "home-casper";
    };

    ##################
    ## NixOs config ##
    ##################

    nixosConfigurations.technative-casper = makeNixosConf {
      hostname = "technative-casper";
      extraModules = [ ./profiles/Work ];
    };
    nixosConfigurations.gaming-casper = makeNixosConf {
      hostname = "gaming-casper";
      extraModules = [ ./profiles/Gaming ];
    };
    nixosConfigurations.server-casper = makeNixosConf {
      hostname = "server-casper";
    };
    nixosConfigurations.home-casper = makeNixosConf {
      hostname = "home-casper";
      extraModules = [ ./profiles/Gaming ];
    };
  };
}
