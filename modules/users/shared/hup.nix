{ ... }: {
  flake.modules.homeManager.shared-hip = { inputs, pkgs, ... }:
    let
      hip-tmux-switch = pkgs.writeShellScriptBin "hip-tmux-switch" ''
        session="$1"; repo="$2"; target="$3"

        tmux="${pkgs.tmux}/bin/tmux"

        sess="$(printf '%s' "$session" | tr ':.' '--')"
        win="$(printf  '%s' "$repo"    | tr ':.' '--')"

        left=""

        if ! "$tmux" has-session -t "=$sess" 2>/dev/null; then
          left="$("$tmux" new-session -d -s "$sess" -n "$win" -c "$target" -P -F '#{pane_id}')"
        elif ! "$tmux" list-windows -t "=$sess" -F '#W' | grep -qx "$win"; then
          left="$("$tmux" new-window -d -t "=$sess" -n "$win" -c "$target" -P -F '#{pane_id}')"
        fi

        if [ -n "$left" ]; then
          right="$("$tmux" split-window -d -h -l 50% -t "$left" -c "$target" -P -F '#{pane_id}')"
          "$tmux" split-window -d -v -l 50% -t "$right" -c "$target"
          "$tmux" select-pane -t "$left"
        fi

        "$tmux" switch-client -t "=$sess:$win"
      '';

      hipTui = pkgs.writeShellScriptBin "hip-tui" ''
        set -euo pipefail

        cache="$HOME/.cache/hip/github-caspersonn.json"
        root="$HOME/git"

        [ -f "$cache" ] || exec hip tui "$@"

        clones="$(
          find "$root" -mindepth 3 -maxdepth 3 -type d -name .git -printf '%P\n' 2>/dev/null \
            | awk -F/ -v prefix='gh.' 'NF == 3 && index($1, prefix) == 1 { print substr($1, length(prefix) + 1) "/" $2 }'
        )"

        adds="$(
          printf '%s\n' "$clones" \
            | ${pkgs.jq}/bin/jq -R -s '
                split("\n") | map(select(length > 0)) | map(split("/")) |
                map({
                  Owner: .[0],
                  Name: .[1],
                  Description: "",
                  SSHURL: ("git@github.com:" + .[0] + "/" + .[1] + ".git"),
                  HTTPSURL: ("https://github.com/" + .[0] + "/" + .[1] + ".git"),
                  WebURL: ("https://github.com/" + .[0] + "/" + .[1]),
                  DefaultBranch: "",
                  Archived: false,
                  Fork: false,
                  Visibility: "public",
                  UpdatedAt: "0001-01-01T00:00:00Z"
                })'
        )"

        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq --argjson add "$adds" '
          . as $c
          | ($c.repos | map((.Owner | ascii_downcase) + "/" + (.Name | ascii_downcase))) as $have
          | .repos += ($add | map(
              select((((.Owner | ascii_downcase) + "/" + (.Name | ascii_downcase))) as $key
                     | ($have | index($key)) | not)))
        ' "$cache" > "$tmp"
        mv "$tmp" "$cache"

        exec hip tui "$@"
      '';

      hipConfig = {
        base_dir = "~/git";
        clone_pattern_tpl = "{{.BaseDir}}/{{.Short}}.{{.OwnerLower}}/{{.Repo}}";

        default_mode = "management";
        modes = {
          management = {
            header = [ "breadcrumb" ];
            footer = [ "filter" "facet_status" "status_message" "position_indicator" "action_menu" ];
          };
          multiplex = {
            header = [ ];
            footer = [ "switch_hint" "filter" ];
            switch_command = "'${hip-tmux-switch}/bin/hip-tmux-switch' '{{if .Collection}}col->{{.Collection}}{{else}}{{.Short}}->{{.OwnerLower}}{{end}}' '{{.Repo}}' '{{.Target}}'";
          };
        };

        providers = [
          {
            name = "github-caspersonn";
            type = "github";
            short = "gh";
            username = "caspersonn";
            web_url = "https://github.com";
            clone_protocol = "ssh";
            auth.cli = "gh";
            all_owners = true;
            include_archived = false;
            include_forks = true;
          }
        ];
      };
    in {
      home.packages = [
        inputs.hip.packages."${pkgs.system}".default
        hip-tmux-switch
        hipTui
      ];

      xdg.configFile."hip/config.yaml" = {
        source = (pkgs.formats.yaml { }).generate "hip-config.yaml" hipConfig;
        force = true;
      };
    };
}
