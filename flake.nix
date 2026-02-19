{
  description = "Best config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs2405.url = "github:NixOS/nixpkgs/nixos-24.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    bmc.url = "github:wearetechnative/bmc";
    race.url = "github:wearetechnative/race";
    jsonify-aws-dotfiles.url = "github:wearetechnative/jsonify-aws-dotfiles";
    nixpkgs-cosmic.follows = "nixos-cosmic/nixpkgs";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    stylix.url = "github:danth/stylix/release-25.11";
    croctalk.url = "github:wearetechnative/croctalk";
    slack2zammad.url = "github:wearetechnative/slack2zammad";
    dirtygit.url = "github:mipmip/dirtygit";
    swww.url = "github:LGFae/swww";
    nixvim.url = "github:Caspersonn/nixvim";
    openspec.url = "github:Fission-AI/OpenSpec";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
    elephant.url = "github:abenz1267/elephant";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    vogix16.url = "github:i-am-logger/vogix16";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    monitoring.url = "/home/casper/git/wearetechnative/monitoring";
    # Dendritic tools
    import-tree.url = "github:vic/import-tree";
    pokemon-tracker.url = "github:Caspersonn/pokemon-tracker";
    omarchy-nix = {
      url = "github:caspersonn/lkasper-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Import all flake-parts modules
      imports = [
        # Enable flake.modules support
        flake-parts.flakeModules.modules
	inputs.home-manager.flakeModules.home-manager
        # Automatically import all dendritic modules from modules/
        (inputs.import-tree ./modules)
        # Centralized home-manager configurations
        #./parts/home-manager.nix
      ];

      systems = [ "x86_64-linux" "aarch64-linux" ];
    };
}
