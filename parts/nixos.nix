{
  inputs,
  lib,
  ...
}: let
  inherit (inputs) nixpkgs nixpkgs2405 unstable home-manager agenix nixos-hardware monitoring bmc race jsonify-aws-dotfiles openspec spicetify-nix walker;

  # Import helper from overlays module
  importFromChannelForSystem = inputs.self.lib.importFromChannelForSystem;

  makeNixosConf = {
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
    username ? "casper",
    gnome ? false,
    hyprland ? false,
    cosmic ? false,
    kde ? false,
    ...
  }: let
    desktopModules =
      nixpkgs.lib.optionals gnome [../modules/desktop-environments/gnome]
      ++ nixpkgs.lib.optionals hyprland [../modules/desktop-environments/hyprland]
      ++ nixpkgs.lib.optionals cosmic [../modules/desktop-environments/cosmic]
      ++ nixpkgs.lib.optionals kde [../modules/desktop-environments/kde];
  in
    nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs username hostname;
        roles = {
          inherit
            gnome
            hyprland
            cosmic
            kde
            ;
        };
      };
      modules = let
        defaults = {pkgs, ...}: {
          nixpkgs.overlays = [(import ../overlays)];
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
      in
        [
          defaults
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.framework-13-7040-amd
          agenix.nixosModules.default
          monitoring.nixosModules.monitoring
          spicetify-nix.nixosModules.spicetify
          extraPkgs
          {home-manager.useGlobalPkgs = true;}
        ]
        ++ desktopModules
        ++ extraModules;
    };
in {
  flake.nixosConfigurations = {
    technative-casper = makeNixosConf {
      hostname = "technative-casper";
      extraModules = [../profiles/Work];

      gnome = false;
      hyprland = true;
    };

    gaming-casper = makeNixosConf {
      hostname = "gaming-casper";
      extraModules = [../profiles/Gaming];

      gnome = false;
      hyprland = true;
    };

    server-casper = makeNixosConf {
      hostname = "server-casper";
      system = "aarch64-linux";
      extraModules = [
        ../profiles/Server
        ../modules/services/service-bluetooth_reciever.nix
      ];

      gnome = false;
      hyprland = false;
    };

    personal-casper = makeNixosConf {
      hostname = "personal-casper";
      extraModules = [../profiles/Personal];

      gnome = false;
      hyprland = true;
    };
  };
}
