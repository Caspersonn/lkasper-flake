{ inputs, ... }: {
  flake.modules.nixos.binary-cache-signing = { config, lib, pkgs, ... }: {

      nix.settings.secret-key-files = [ "/etc/nix/signing-key.sec" ];
    };
}
