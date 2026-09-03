{ ... }: {
  flake.modules.homeManager.shared-rbw = { pkgs, ... }: {
    programs.rbw.enable = true;

    programs.fish = {
      functions = {
        # Pad naar het bestand met het actieve profiel: bron van waarheid voor
        # niet-fish consumers (o.a. de tmux status bar). Als functie i.p.v.
        # globale variabele in config.fish, zodat het ook werkt in shells die
        # al liepen voor de laatste rebuild.
        __rbw_state_file = ''
          echo $HOME/.local/state/rbw-profile
        '';

        # Profielen: ~/.config/rbw = (default), ~/.config/rbw-<naam> = <naam>
        __rbw_profiles = ''
          test -d $HOME/.config/rbw; and echo '(default)'
          for dir in (command find -L $HOME/.config -maxdepth 1 -type d -name 'rbw-*' 2>/dev/null | sort)
            string replace -r '^.*/rbw-' "" -- $dir
          end
        '';

        __rbw_profile_set = ''
          set -l profile $argv[1]

          # Universele variabele: elke draaiende fish shell ziet dit direct.
          # Eerst lokale/globale shadows weg, anders maskeren die de universele.
          set -e -l RBW_PROFILE 2>/dev/null
          set -e -g RBW_PROFILE 2>/dev/null
          if test -n "$profile"
            set -Ux RBW_PROFILE $profile
          else
            set -e -U RBW_PROFILE 2>/dev/null
          end

          # Bestand voor de tmux bar en niet-fish shells.
          set -l state (__rbw_state_file)
          if not command mkdir -p (path dirname -- $state)
            echo "Kan $state niet aanmaken" >&2
            return 1
          end
          if test -e $state; and not test -f $state
            echo "$state is geen bestand" >&2
            return 1
          end
          printf '%s\n' "$profile" >$state

          # Nieuwe panes erven dit; de bar leest het bestand.
          command tmux setenv -g RBW_PROFILE "$profile" 2>/dev/null
          command tmux refresh-client -S 2>/dev/null
          return 0
        '';

        ## TODO:
        # Fallback voor shells die starten zonder universele variabele.
        __rbw_profile_load = ''
          set -q RBW_PROFILE; and test -n "$RBW_PROFILE"; and return 0
          set -l state (__rbw_state_file)
          test -f $state; or return 0
          # Pipe i.p.v. argument: bij een leeg bestand zou `string trim --`
          # zonder argumenten van stdin (de tty) gaan lezen en blijven hangen.
          set -l profile (command cat $state | string trim)
          test -n "$profile"; or return 0
          set -Ux RBW_PROFILE $profile
        '';

        rbwsel = ''
          set -l profiles (__rbw_profiles)
          if test (count $profiles) -eq 0
            echo "Geen rbw profielen gevonden in $HOME/.config" >&2
            return 1
          end

          set -l selected
          if set -q argv[1]
            # Niet-interactief: rbwsel work / rbwsel default
            set selected $argv[1]
            test "$selected" = default; and set selected '(default)'
            if not contains -- $selected $profiles
              echo "Onbekend profiel: $argv[1] (beschikbaar: $profiles)" >&2
              return 1
            end
          else
            set -l current '(default)'
            set -q RBW_PROFILE; and test -n "$RBW_PROFILE"; and set current $RBW_PROFILE
            set selected (printf '%s\n' $profiles \
              | ${pkgs.gum}/bin/gum choose --header 'Kies RBW profiel' --selected "$current")
            or return 0
            test -z "$selected"; and return 0
          end

          set -l profile ""
          test "$selected" != '(default)'; and set profile $selected

          __rbw_profile_set "$profile"; or return 1
          echo "RBW profiel: $selected"
        '';
      };

      interactiveShellInit = ''
        __rbw_profile_load
        complete -c rbwsel -f -a "(__rbw_profiles | string replace '(default)' default)"
      '';
    };
  };
}
