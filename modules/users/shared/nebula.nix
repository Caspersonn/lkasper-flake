{ config, lib, ... }:
let
  hostLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: node: "${name} ${node.address}") config.casper.nebula.nodes
  );
in
{
  flake.modules.homeManager.shared-nebula = { pkgs, ... }:
    let
      nebula-ssh = pkgs.writeShellApplication {
        name = "nebula-ssh";

        runtimeInputs = [
          pkgs.fzf
          pkgs.tmux
          pkgs.gnugrep
          pkgs.openssh
          pkgs.coreutils
        ];

        text = ''
          hosts="${hostLines}"

          choice="$(printf '%s\n' "$hosts" \
            | fzf --reverse --prompt='ssh > ' --header='nebula hosts')" || exit 0
          if [ -z "$choice" ]; then
            exit 0
          fi

          name="''${choice%% *}"
          session="nebula"

          if ! tmux has-session -t "=$session" 2>/dev/null; then
            tmux new-session -d -s "$session" -n "$name" "ssh $name.mesh"
          elif ! tmux list-windows -t "=$session" -F '#W' | grep -qx "$name"; then
            tmux new-window -d -t "=$session" -n "$name" "ssh $name.mesh"
          fi

          tmux switch-client -t "=$session:$name"
        '';
      };
    in
    {
      home.packages = [ nebula-ssh ];

      programs.tmux.extraConfig = ''
        bind H popup -E -w 60% -h 60% 'nebula-ssh'
      '';
    };
}
