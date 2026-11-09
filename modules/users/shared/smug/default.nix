{ ... }: {
  flake.modules.homeManager.shared-smug = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "smg" ''
        profile="$(${pkgs.smug}/bin/smug list | ${pkgs.gum}/bin/gum filter)"
        [ -z "$profile" ] && exit 0
        ${pkgs.smug}/bin/smug start "$profile"
        ${pkgs.tmux}/bin/tmux switch -t "$profile"
      '')
    ];

    home.file = {
      ".config/smug" = {
        source = ./smug;
        recursive = true;
      };
    };
  };
}
