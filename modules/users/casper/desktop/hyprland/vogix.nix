{inputs, ... }: {
  flake.modules.homeManager.vogix = { pkgs, config, lib, username, hostname, ... }:
    {
      #  programs.vogix16 = {
      #    enable = true;
      #  };
    };
}
