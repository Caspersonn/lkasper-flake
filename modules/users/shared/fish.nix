{ ... }: {
  flake.modules.homeManager.shared-fish = { pkgs, ... }: {
    # `grc` plugin needs the grc binary on PATH, else it warns on every startup.
    home.packages = [ pkgs.grc ];

    programs.fish = {
      enable = true;

      plugins = [
        # Colorized command output
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
        { name = "aws"; src = pkgs.fishPlugins.aws; }
        { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages; }
        # Manually packaged `z` jump plugin
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

        # Select an AWS profile via bmc and load it into the current shell.
        aws-switch = ''
          command bmc profsel $argv | __load_exports
        '';
        swte = ''
          command bmc profsel -p technative $argv | __load_exports
        '';

        # Launch Claude Code against the Technative Bedrock playground.
        bcd = ''
          set -gx AWS_PROFILE 'TEC-playground-student14'
          set -gx CLAUDE_CODE_USE_BEDROCK 1
          set -gx ANTHROPIC_MODEL 'arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
          set -gx AWS_REGION eu-central-1
          claude $argv
        '';
        bcdc = ''
          set -gx AWS_PROFILE 'TEC-playground-student14'
          set -gx CLAUDE_CODE_USE_BEDROCK 1
          set -gx ANTHROPIC_MODEL 'arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0'
          set -gx AWS_REGION eu-central-1
          claude -c $argv
        '';

        # Gruvbox prompt — left side: user@host, cwd, git branch + dirty/clean.
        # Mirrors the old oh-my-zsh "casper" theme.
        fish_prompt = ''
          set -l last_status $status

          # success (green) / error (red) arrow
          if test $last_status -eq 0
            set_color --bold b8bb26
          else
            set_color --bold fb4934
          end
          echo -n '➜ '

          # user@host
          set_color 83a598
          echo -n (whoami)
          set_color 458588
          echo -n '@'(prompt_hostname)
          set_color normal
          echo -n ' '

          # current directory
          set_color --bold 8ec07c
          echo -n (prompt_pwd)
          set_color normal
          echo -n ' '

          # git branch + state
          set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
          if test -n "$branch"
            set_color 83a598
            echo -n '  '
            set_color fb4934
            echo -n $branch
            set -l dirty (command git status --porcelain 2>/dev/null)
            if test -n "$dirty"
              set_color fabd2f
              echo -n ' '
            else
              set_color b8bb26
              echo -n ' ✓'
            end
            set_color normal
            echo -n ' '
          end
        '';

        # Right side: active AWS profile + terraform backend state.
        fish_right_prompt = ''
          if set -q AWS_PROFILE
            set_color d3869b
            echo -n "  $AWS_PROFILE"
            set_color normal
          end
          if test -f .terraform/tfbackend.state
            set_color b8bb26
            echo -n ' 󱁢 '(cat .terraform/tfbackend.state)
            set_color normal
          end
        '';
      };

      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        # --- Gruvbox syntax-highlighting colors ---
        set -g fish_color_normal        ebdbb2
        set -g fish_color_command       b8bb26
        set -g fish_color_keyword       fb4934
        set -g fish_color_quote         b8bb26
        set -g fish_color_redirection   8ec07c
        set -g fish_color_end           fe8019
        set -g fish_color_error         fb4934
        set -g fish_color_param         ebdbb2
        set -g fish_color_comment       a89984
        set -g fish_color_operator      8ec07c
        set -g fish_color_escape        fe8019
        set -g fish_color_autosuggestion 928374
        set -g fish_color_cwd           fabd2f
        set -g fish_color_user          8ec07c
        set -g fish_color_host          83a598
        set -g fish_color_selection     --background=3c3836
        set -g fish_color_search_match  --background=3c3836
        set -g fish_pager_color_prefix  fabd2f
        set -g fish_pager_color_completion ebdbb2
        set -g fish_pager_color_description a89984

        # Personal bin dirs first on PATH. Added unconditionally (unlike
        # fish_add_path, which skips dirs that don't exist yet) because e.g.
        # claude drops self-updates into ~/.local/bin before it exists.
        for dir in $HOME/bin $HOME/.local/bin
          contains $dir $PATH; or set -gx PATH $dir $PATH
        end

        # rme completion (mirrors the zsh `compadd $(rme --completions)`)
        complete -c rme -f -a "(rme --completions)"

        # Load runtime secrets written by the neovim avante / google tooling
        for f in /tmp/avante-bedrock /tmp/avante-openai /tmp/google-bedrock /tmp/google-engine-bedrock
          test -f $f; and __load_exports <$f
        end
      '';
    };
  };
}
