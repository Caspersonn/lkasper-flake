{
  description = "Best config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    bmc.url = "github:wearetechnative/bmc";
    race.url = "github:wearetechnative/race";
    jsonify-aws-dotfiles.url = "github:wearetechnative/jsonify-aws-dotfiles";
    nixpkgs-cosmic.follows = "nixos-cosmic/nixpkgs";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    stylix.url = "github:danth/stylix/release-25.05";
    croctalk.url = "github:wearetechnative/croctalk";
    slack2zammad.url = "github:wearetechnative/slack2zammad";
    dirtygit.url = "github:mipmip/dirtygit";
    swww.url = "github:LGFae/swww";
    walker.url = "github:abenz1267/walker";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
    nixos-healthchecks = {
      url = "github:mrvandalo/nixos-healthchecks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixtendo-switch, nixpkgs-cosmic, nixos-cosmic, stylix, croctalk, slack2zammad, dirtygit, nixos-healthchecks, swww, walker }:


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
      stylix.homeModules.stylix
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
      desktopModules =
        nixpkgs.lib.optionals gnome [ ./modules/desktop-environments/gnome ] ++
        nixpkgs.lib.optionals hyprland [ ./modules/desktop-environments/hyprland ] ++
        nixpkgs.lib.optionals cosmic [ ./modules/desktop-environments/cosmic ] ++
        nixpkgs.lib.optionals kde [ ./modules/desktop-environments/kde ];
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
              nixos-healthchecks.packages.${system}.healthchecks
              walker.packages.${system}.default
              #slack2zammad.packages."${system}".slack2zammad
              #croctalk.packages."${system}".croctalk
              #croctalk.nixosModules."${system}".croctalk
            ];
          };
        in [
            defaults
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-healthchecks.nixosModules.default
                  #nixos-healthchecks.flakeModule
            extraPkgs
            { home-manager.useGlobalPkgs = true; }
           ] ++ desktopModules ++ extraModules;
    };

  in
  {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-classic;

    ########################
    ## HomeManager config ##
    ########################

    homeConfigurations."technative-casper@linuxdesktop" = makeHomeConf {
      system   = "x86_64-linux";
      hostname = "technative-casper";
    };

    # TODO: Change name to casper
    homeConfigurations."technative-server@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "technative-lucak";
        username = "lucak";
        homedir  = "/home/lucak";
        desktop  = false;
    };

    # TODO: Change name to casper
    homeConfigurations."dreammachine-luca@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "server-casper";
        username = "luca";
        homedir  = "/home/luca";
        desktop  = false;
    };

    homeConfigurations."gaming-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "gaming-casper";
    };

    homeConfigurations."server-casper@linuxdesktop" = makeHomeConf {
        system   = "aarch64-linux";
        hostname = "server-casper";
        desktop  = true;
    };

    homeConfigurations."personal-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "personal-casper";
    };

    ##################
    ## NixOs config ##
    ##################

    nixosConfigurations.technative-casper = makeNixosConf {
      hostname     = "technative-casper";
      extraModules = [ ./profiles/Work ];
      gnome        = false;
      hyprland     = true;
    };
    nixosConfigurations.gaming-casper = makeNixosConf {
      hostname = "gaming-casper";
      extraModules = [ ./profiles/Gaming ./modules/services/service-mysql.nix ];
      hyprland = true;
      gnome = false;
    };
    nixosConfigurations.server-casper = makeNixosConf {
      hostname     = "server-casper";
      extraModules = [ ./profiles/Server ./modules/services/service-bluetooth_reciever.nix ];
      system       = "aarch64-linux";
      gnome        = true;
    };
    nixosConfigurations.personal-casper = makeNixosConf {
      hostname = "personal-casper";
      extraModules = [ ./profiles/Personal ];
      hyprland = true;
      gnome = false;
    };
  };
}
