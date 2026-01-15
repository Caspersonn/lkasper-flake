{inputs, ...}: let
  inherit (inputs) nixpkgs unstable home-manager stylix walker vogix16;

  # Import helper from overlays module
  importFromChannelForSystem = inputs.self.lib.importFromChannelForSystem;

  makeHomeConf = {
    username ? "casper",
    hostname,
    homedir ? "/home/casper",
    system ? "x86_64-linux",
    gnome ? false,
    hyprland ? false,
    ...
  }:
    home-manager.lib.homeManagerConfiguration {
      modules =
        [
          stylix.homeModules.stylix

          (import ../home)
          {
            home.stateVersion = "24.11";
            home.username = username;
            home.homeDirectory = homedir;
            roles.gnome.enable = gnome;
            roles.hyprland.enable = hyprland;
          }
        ]
        ++ [
          walker.homeManagerModules.default
          vogix16.homeManagerModules.default
        ];
      pkgs = importFromChannelForSystem system nixpkgs;
      extraSpecialArgs = {
        inherit system inputs hostname username;
        unstable = importFromChannelForSystem system unstable;
      };
    };
in {
  flake.homeConfigurations = {
    "technative-casper@linuxdesktop" = makeHomeConf {
      system = "x86_64-linux";
      hostname = "technative-casper";

      gnome = true;
      hyprland = true;
    };

    # TODO: Change name to casper
    "technative-server@linuxdesktop" = makeHomeConf {
      system = "x86_64-linux";
      hostname = "technative-lucak";
      username = "lucak";
      homedir = "/home/lucak";

      gnome = false;
      hyprland = false;
    };

    # TODO: Change name to casper
    "dreammachine-luca@linuxdesktop" = makeHomeConf {
      system = "x86_64-linux";
      hostname = "dreammachine";

      gnome = false;
      hyprland = false;
    };

    "gaming-casper@linuxdesktop" = makeHomeConf {
      system = "x86_64-linux";
      hostname = "gaming-casper";

      gnome = false;
      hyprland = true;
    };

    "server-casper@linuxdesktop" = makeHomeConf {
      system = "aarch64-linux";
      hostname = "server-casper";

      gnome = false;
      hyprland = false;
    };

    "personal-casper@linuxdesktop" = makeHomeConf {
      system = "x86_64-linux";
      hostname = "personal-casper";

      gnome = false;
      hyprland = true;
    };
  };
}
