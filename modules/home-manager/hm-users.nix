{ inputs, ... }: {
  flake.modules.nixos.hm-users = { config, pkgs, ... }: {
    users.defaultUserShell = pkgs.fish;
    programs.fish.enable = true;

    nix.settings.require-sigs = false;
    nix.settings.trusted-public-keys = ["gaming-casper:KYvnn1Wx4w2rbz7dQQHUvHu+0N5NxsDlLkSpIX3WGeM="];
  };
}
