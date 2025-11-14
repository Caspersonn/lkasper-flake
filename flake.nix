{
  description = "Best config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs2405.url = "github:NixOS/nixpkgs/nixos-24.05";
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
    elephant.url = "github:abenz1267/elephant";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
  };

  outputs = inputs@{ self, nixpkgs, unstable, home-manager, agenix, bmc, homeage, race, jsonify-aws-dotfiles, nixtendo-switch, nixpkgs-cosmic, nixos-cosmic, stylix, croctalk, slack2zammad, dirtygit, swww, walker, elephant, nixpkgs2405, nixos-hardware }:


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
        homedir  ? "/home/casper",
        system   ? "x86_64-linux",
        gnome    ? false,
        hyprland ? false,
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
              roles.gnome.enable = gnome;
              roles.hyprland.enable = hyprland;
            }
          ] ++ [ inputs.walker.homeManagerModules.default ];
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
        gnome        ? false,
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
                  _module.args.pkgs2405 = importFromChannelForSystem system nixpkgs2405;
                };

                extraPkgs = {
                  environment.systemPackages = [
                    agenix.packages."${system}".agenix
                    race.packages."${system}".race
                    bmc.packages."${system}".bmc
                    jsonify-aws-dotfiles.packages."${system}".jsonify-aws-dotfiles
                  ];
                };
              in [
                  defaults
                  home-manager.nixosModules.home-manager
                  nixos-hardware.nixosModules.framework-13-7040-amd
                  agenix.nixosModules.default
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

        gnome    = true;
        hyprland = true;
      };

      # TODO: Change name to casper
      homeConfigurations."technative-server@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "technative-lucak";
        username = "lucak";
        homedir  = "/home/lucak";

        gnome    = false;
        hyprland = false;
      };

      # TODO: Change name to casper
      homeConfigurations."dreammachine-luca@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "dreammachine";

        gnome    = false;
        hyprland = false;
      };

      homeConfigurations."gaming-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "gaming-casper";

        gnome    = false;
        hyprland = true;
      };

      homeConfigurations."server-casper@linuxdesktop" = makeHomeConf {
        system   = "aarch64-linux";
        hostname = "server-casper";

        gnome    = false;
        hyprland = false;
      };

      homeConfigurations."personal-casper@linuxdesktop" = makeHomeConf {
        system   = "x86_64-linux";
        hostname = "personal-casper";

        gnome    = false;
        hyprland = true;
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
        hostname     = "gaming-casper";
        extraModules = [ ./profiles/Gaming ./modules/services/service-mysql.nix ];

        gnome        = false;
        hyprland     = true;
      };
      nixosConfigurations.server-casper = makeNixosConf {
        hostname     = "server-casper";
        system       = "aarch64-linux";
        extraModules = [ ./profiles/Server ./modules/services/service-bluetooth_reciever.nix ];

        gnome        = false;
        hyprland     = false;
      };
      nixosConfigurations.personal-casper = makeNixosConf {
        hostname     = "personal-casper";
        extraModules = [ ./profiles/Personal ];

        gnome        = false;
        hyprland     = true;
      };
    };
}
