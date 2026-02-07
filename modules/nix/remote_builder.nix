{ inputs, ... }: {
  flake.modules.nixos.remote_builder = { pkgs, config, lib, ... }: {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
