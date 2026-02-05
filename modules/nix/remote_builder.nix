{ inputs, ... } : {
  flake.modules.nixos.remote_builder = { pkgs, ... }: {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];

      builders-use-substitutes = true;

      trusted-users = [ "root" "@wheel" ];
    };

        nix.buildMachines = [
      {
        hostName = "localhost";
        system = pkgs.stdenv.hostPlatform.system;
        supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
      }
    ];

    nix.distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    nix.extraOptions = ''
    builders-use-substitutes = true
    '';
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
