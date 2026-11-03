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
      ];

      xdg.configFile."hip/config.yaml" = {
        source = (pkgs.formats.yaml { }).generate "hip-config.yaml" hipConfig;
        force = true;
      };
    };
}
