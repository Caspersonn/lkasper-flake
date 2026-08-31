{ ... }: {
  flake.modules.homeManager.shared-fish = { pkgs, ... }: {
    # `grc` plugin needs the grc binary on PATH, else it warns on every startup.
    home.packages = [ pkgs.grc ];

    programs.fish = {
      enable = true;

      plugins = [
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        { name = "aws"; src = pkgs.fishPlugins.aws; }
        { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages; }
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
            sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
          };
        }
      ];

      shellAliases = {
        tfswitch = "mkdir -p $HOME/bin; command tfswitch -b $HOME/bin/terraform";
        lin = "vi -c LinnyMenuOpen";
        ner = "vi -c Neotree";
        runbg = "$HOME/.config/hypr/scripts/runbg.sh";
        aws-mfa = "$HOME/lkasper-flake/modules/users/casper/desktop/hyprland/scripts/aws-mfa-auto.sh";
      };

      functions = {
        __load_exports = ''
          while read -l line
            set -l line (string replace -r '^export ' "" -- $line)
            test -z "$line"; and continue
            set -l kv (string split -m 1 = -- $line)
            test (count $kv) -eq 2; and set -gx $kv[1] $kv[2]
          end
        '';

        # bmc wrapper: `profsel` prints shell exports we must load into the session.
        bmc = ''
          if test "$argv[1]" = profsel
            command bmc $argv | __load_exports
          else
            command bmc $argv
          end
        '';

        aws-switch = ''
          command bmc profsel $argv | __load_exports
        '';
        swte = ''
          command bmc profsel -p technative $argv | __load_exports
        '';

        fish_prompt = ''
          set -l last_status $status
          set -x PATH /home/casper/bin $PATH

          # success (green) / error (red) arrow
          if test $last_status -eq 0
            set_color --bold $lkh_green
          else
            set_color --bold $lkh_red
          end
          echo -n '➜ '

          # user@host
          set_color $lkh_blue
          echo -n (whoami)
          set_color $lkh_dim
          echo -n '@'(prompt_hostname)
          set_color normal
          echo -n ' '

          # current directory
          set_color --bold $lkh_cyan
          echo -n (prompt_pwd)
          set_color normal
          echo -n ' '

          # git branch + state
          set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
          if test -n "$branch"
            set_color $lkh_blue
            echo -n ' '
            set_color $lkh_red
            echo -n $branch
            set -l dirty (command git status --porcelain 2>/dev/null)
            if test -n "$dirty"
              set_color $lkh_yellow
              echo -n ' '
            else
              set_color $lkh_green
              echo -n ' ✓'
            end
            set_color normal
            echo -n ' '
          end
        '';

        # Right side: active AWS profile + terraform backend state.
        fish_right_prompt = ''
          if set -q AWS_PROFILE
            set_color $lkh_magenta
            echo -n "  $AWS_PROFILE"
            set_color normal
          end
          if test -f .terraform/tfbackend.state
            set_color $lkh_green
            echo -n ' 󱁢 '(cat .terraform/tfbackend.state)
            set_color normal
          end
        '';
      };

      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        if test -r ~/.config/lkasper-hyprland/current/fish.fish
          source ~/.config/lkasper-hyprland/current/fish.fish
        end

        for pair in lkh_fg:ebdbb2 lkh_dim:928374 lkh_red:fb5944 lkh_green:b8bb26 lkh_yellow:fabd2f lkh_blue:83a598 lkh_magenta:d3869b lkh_cyan:8ec07c
          set -l kv (string split -m 1 : -- $pair)
          if not set -q $kv[1]
            set -g $kv[1] $kv[2]
          end
        end

        # rme completion (mirrors the zsh `compadd $(rme --completions)`)
        complete -c rme -f -a "(rme --completions)"
      '';
    };
  };
}
