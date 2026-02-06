{ inputs, ... } : {
  flake.modules.nixos.remote_builder = { pkgs, ... }: {

    nix.buildMachines = [
      {
        hostName = "remotebuilder";
        sshUser = "remotebuild";
        sshKey = "/root/.ssh/remotebuild";
        system = pkgs.stdenv.hostPlatform.system;
        supportedFeatures = [ "nixos-test" "big-parallel" "kvm" ];
      }
    ];

    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
