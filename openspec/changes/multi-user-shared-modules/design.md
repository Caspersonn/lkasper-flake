# Design: Multi-User Separation with Shared Home-Manager Modules

## Context

The home-manager migration to the dendritic pattern (`migrate-home-manager-to-dendritic`) established per-user modules under `modules/users/`. Currently:

- **casper**: 20 active HM modules, 6 inactive, all prefixed `casper-*`
- **antonia**: 5 active HM modules, largely duplicating casper's config
- **No shared layer**: Each user reimplements the same base config
- **Work/personal mixed**: TechNative aliases and AWS config live in casper's modules
- **System-wide work packages**: `technative.nix` installs ~50 packages for all users

The dendritic pattern supports two key aspect patterns for this refactor:
- **Simple Aspect**: Independent feature modules (`shared-*`) importable by any user
- **Inheritance Aspect**: User modules import shared parents and override specific values inline

### Constraints

- Must maintain all current home-manager functionality for `casper` and `antonia`
- Must work with existing `makeHomeConf` helper (supports `username` and `homedir` parameters)
- All modules must follow import-tree conventions (`{ inputs, ... }:` wrapper, git-tracked)
- `lucak` and `casper` share the same SSH key and git identity
- The `omarchy-nix` `lkh-*` modules remain unchanged (external dependency)
- Hardcoded `/home/casper/` paths must be fixed during migration

### Stakeholders

- `casper` — personal user (gaming, personal projects)
- `lucak` — work user (TechNative, AWS, terraform)
- `antonia` — partner (light usage: browsing, GNOME desktop)

## Goals / Non-Goals

### Goals

- Create shared HM modules with base configuration usable by all users
- Create `lucak` work user with TechNative tooling via home-manager
- Apply Inheritance Aspect for per-user overrides (no duplicate modules)
- Move work packages from system-wide to `lucak`-specific home.packages
- Fix hardcoded `/home/casper/` paths
- Clean up inactive modules
- Simplify antonia's config to use shared modules

### Non-Goals

- Changing desktop environment functionality or keybindings
- Creating different Hyprland themes per user (user will do this separately)
- Migrating `omarchy-nix` modules or changing how they work
- Refactoring system-wide NixOS modules (only `technative.nix` is affected)
- Setting up agenix secrets for `lucak` (can be done separately)

## Decisions

### Decision 1: Shared Module Naming and File Convention

**Pattern**: Shared modules registered as `flake.modules.homeManager.shared-<aspect>`.

**File convention**:
- Single `.nix` file for modules without accompanying config files
- Directory with `default.nix` for modules that need extra files (config dirs, themes, YAML)

```
modules/users/shared/
├── zsh/                          ← directory: has ohmyzsh-casper/ theme
│   ├── default.nix
│   └── ohmyzsh-casper/
├── opencode/                     ← directory: has config/ dir
│   ├── default.nix
│   └── config/
├── dirty-repo-scanner/           ← directory: has config.yml
│   ├── default.nix
│   └── config.yml
├── git.nix                       ← single file
├── neovim.nix                    ← single file
├── firefox.nix                   ← single file
├── tmux.nix                      ← single file
├── fzf.nix                       ← single file
├── zoxide.nix                    ← single file
├── autojump.nix                  ← single file
├── atuin.nix                     ← single file
├── jq.nix                        ← single file
├── tses.nix                      ← single file
├── font.nix                      ← single file
├── age.nix                       ← single file
└── technative.nix                ← single file (work packages)
```

**Why**: Follows dendritic convention — no file organization restrictions, but consistent naming within this change. The `shared-` prefix makes user ownership explicit and avoids naming conflicts with existing system-level modules.

### Decision 2: Inheritance Aspect for Per-User Overrides

**Pattern**: User `home-manager.nix` imports shared modules as parents, then overrides specific attributes inline. No separate per-user wrapper modules for git/zsh/firefox.

**How NixOS module merging works**:
- `programs.zsh.shellAliases` is an attrset — user-defined aliases **merge** with shared aliases
- `programs.git.settings.user` is an attrset — user values **override** shared defaults
- `programs.firefox.profiles` is an attrset — user profiles **add** to shared base (shared defines extensions, user defines profiles)
- `programs.firefox.policies` uses `lib.mkForce` or merges naturally depending on structure

**Example — casper/home-manager.nix**:
```nix
{ inputs, self, ... }: {
  flake.modules.homeManager.casper = { pkgs, config, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      # Omarchy-nix (Hyprland desktop)
      lkh-themes lkh-ags lkh-hyprland lkh-ghostty lkh-hyprlock
      lkh-hyprpaper lkh-hypridle lkh-btop lkh-zsh lkh-starship
      lkh-direnv lkh-fonts lkh-zoxide lkh-hyprshot

      # Shared modules (parent aspects)
      shared-zsh shared-git shared-neovim shared-fzf shared-zoxide
      shared-autojump shared-atuin shared-jq shared-tmux shared-tses
      shared-font shared-firefox shared-age shared-opencode
      shared-dirty-repo-scanner

      # Casper-only complex modules
      casper-nextcloud
      casper-vesktop
      casper-smug
    ]);

    # ── Inheritance overrides ──────────────────────────────

    # Git identity
    programs.git.settings.user = {
      email = "lucakasper8@gmail.com";
      name = "Caspersonn";
    };

    # Personal zsh aliases (merged with shared base)
    programs.zsh.shellAliases = {
      lin = "vi -c LinnyMenuOpen";
      ner = "vi -c Neotree";
      runbg = "$HOME/.config/hypr/scripts/runbg.sh";
    };

    # Personal Firefox profile
    programs.firefox.profiles.personal = {
      id = 0;
      name = "personal";
      isDefault = true;
      search.default = "ddg";
      settings = {
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.bookmarks.addedImportButton" = false;
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = "0";
        "sidebar.verticalTabs" = true;
        "browser.startup.homepage" = "https://search.nixos.org";
        "browser.startup.page" = 3;
        "browser.newtabpage.pinned" = [
          { title = "YouTube"; url = "https://youtube.com"; }
          { title = "Gmail"; url = "https://gmail.com"; }
        ];
      };
    };

    # Librewolf (disabled, personal only)
    programs.librewolf = {
      enable = false;
      package = pkgs.librewolf;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
```

**Example — lucak/home-manager.nix**:
```nix
{ inputs, self, ... }: {
  flake.modules.homeManager.lucak = { pkgs, config, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      # Omarchy-nix (zelfde Hyprland desktop)
      lkh-themes lkh-ags lkh-hyprland lkh-ghostty lkh-hyprlock
      lkh-hyprpaper lkh-hypridle lkh-btop lkh-zsh lkh-starship
      lkh-direnv lkh-fonts lkh-zoxide lkh-hyprshot

      # Shared modules (parent aspects)
      shared-zsh shared-git shared-neovim shared-fzf shared-zoxide
      shared-autojump shared-atuin shared-jq shared-tmux shared-tses
      shared-font shared-firefox shared-age shared-opencode
      shared-dirty-repo-scanner

      # Work shared modules
      shared-technative

      # Lucak-only complex modules
      lucak-aws
    ]);

    # ── Inheritance overrides ──────────────────────────────

    # Git identity (zelfde account als casper)
    programs.git.settings.user = {
      email = "lucakasper8@gmail.com";
      name = "Caspersonn";
    };

    # Werk zsh aliases (merged with shared base)
    programs.zsh.shellAliases = {
      tfplan = "$HOME/git/wearetechnative/race/tfplan.sh";
      tfswitch = "mkdir -p ~/bin ; tfswitch -b $HOME/bin/terraform";
      tfapply = "$HOME/git/wearetechnative/race/tfapply.sh";
      tfdestroy = "$HOME/git/wearetechnative/race/tfdestroy.sh";
      aws-switch = ". bmc profsel";
      aws-mfa = "$HOME/lkasper-flake/modules/users/casper/desktop/hyprland/scripts/aws-mfa-auto.sh";
      bcd = "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude";
      bcdc = "export AWS_PROFILE='TEC-playground-student14' && export CLAUDE_CODE_USE_BEDROCK=1 && export ANTHROPIC_MODEL='arn:aws:bedrock:eu-central-1:939665396134:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0' && export AWS_REGION=eu-central-1 && claude -c";
    };

    # Werk Firefox profile
    programs.firefox.profiles.work = {
      id = 0;
      name = "work";
      isDefault = true;
      search.default = "ddg";
      settings = {
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.bookmarks.addedImportButton" = false;
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = "0";
        "sidebar.verticalTabs" = true;
        "browser.startup.homepage" = "https://search.nixos.org";
        "browser.startup.page" = 3;
        "browser.newtabpage.pinned" = [
          { title = "YouTube"; url = "https://youtube.com"; }
          { title = "Outlook"; url = "https://outlook.com"; }
        ];
      };
    };

    # AWS extend switch roles extension (werk only)
    programs.firefox.policies.ExtensionSettings."aws-extend-switch-roles@toshi.tilfin.com" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/aws-extend-switch-roles3/latest.xpl";
      installation_mode = "force_installed";
    };
    # Granted extension (werk only)
    programs.firefox.policies.ExtensionSettings."{b5e0e8de-ebfe-4306-9528-bcc18241a490}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/granted/latest.xpl";
      installation_mode = "force_installed";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
```

**Example — antonia/home-manager.nix (simplified)**:
```nix
{ inputs, self, ... }: {
  flake.modules.homeManager.antonia = { pkgs, ... }: {
    imports = with inputs.self.modules.homeManager; [
      # Shared modules
      shared-zsh shared-git shared-neovim shared-fzf shared-zoxide
      shared-autojump shared-atuin shared-jq shared-tmux shared-tses
      shared-font shared-firefox shared-age

      # Antonia desktop
      gnome
    ];

    # ── Inheritance overrides ──────────────────────────────

    # Git identity
    programs.git.settings.user = {
      email = "antoniagosker@gmail.com";
      name = "antonia";
    };
    programs.git.settings.push.default = "simple";
    programs.git.settings.branch.autosetupmerge = true;

    # Personal Firefox profile
    programs.firefox.profiles.personal = {
      id = 0;
      name = "personal";
      isDefault = true;
      search.default = "ddg";
      settings = {
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.bookmarks.addedImportButton" = false;
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = "0";
        "sidebar.verticalTabs" = false;
      };
    };

    nixpkgs.config.allowUnfree = true;
  };
}
```

**Why**: Eliminates ~9 per-user wrapper modules. The NixOS module system handles merging naturally. Users only define what's different from the shared base.

### Decision 3: Shared Module Content — What Goes Where

**shared-zsh** — base shell config, NO aliases:
```nix
{ ... }: {
  flake.modules.homeManager.shared-zsh = { config, ... }: {
    home.file.".ohmyzsh-casper" = {
      source = ./ohmyzsh-casper;
      recursive = true;
    };
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        PATH=$HOME/bin:$PATH
        set -o allexport
        compdef _rme rme
        _rme() { compadd $(rme --completions) }
        if [ -f /tmp/avante-bedrock ]; then source /tmp/avante-bedrock; fi
        if [ -f /tmp/avante-openai ]; then source /tmp/avante-openai; fi
        if [ -f /tmp/google-bedrock ]; then source /tmp/google-bedrock; fi
        if [ -f /tmp/google-engine-bedrock ]; then source /tmp/google-engine-bedrock; fi
        set +o allexport
      '';
      oh-my-zsh = {
        enable = true;
        theme = "casper";
        custom = "${config.home.homeDirectory}/.ohmyzsh-casper";
        plugins = [ "git" "fzf" "autojump" "dirhistory" ];
      };
    };
  };
}
```

Note: `"aws"` and `"terraform"` oh-my-zsh plugins move to `lucak`'s override:
```nix
# In lucak/home-manager.nix
programs.zsh.oh-my-zsh.plugins = [ "git" "aws" "fzf" "autojump" "dirhistory" "terraform" ];
```

**shared-git** — base settings, NO identity:
```nix
{ ... }: {
  flake.modules.homeManager.shared-git = { ... }: {
    programs.git = {
      enable = true;
      settings = {
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        branch.autoSetupMerge = "simple";
        pull.rebase = true;
        merge.tool = "splice";
      };
    };
    programs.gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
  };
}
```

**shared-firefox** — extensions only, NO profiles:
```nix
{ ... }: {
  flake.modules.homeManager.shared-firefox = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      policies.ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpl";
          installation_mode = "force_installed";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpl";
          installation_mode = "force_installed";
        };
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpl";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
```

Note: `aws-extend-switch-roles` and `granted` extensions are werk-only — moved to `lucak/home-manager.nix` override.

**shared-technative** — work packages as home.packages:
```nix
{ inputs, ... }: {
  flake.modules.homeManager.shared-technative = { pkgs, ... }: {
    home.packages = with pkgs; [
      inputs.jsonify-aws-dotfiles.packages."${pkgs.system}".jsonify-aws-dotfiles
      inputs.bmc.packages."${pkgs.system}".bmc
      inputs.race.packages."${pkgs.system}".race
      inputs.ssmsh.packages."${pkgs.system}".default
      inputs.aws-tui.packages."${pkgs.system}".default
      attic-client aws-mfa aws-nuke awscli
      beam27Packages.elixir bruno docker entr erlang_28
      fastfetch gh gimp3 git-remote-codecommit granted
      hedgedoc inkscape-with-extensions inotify-tools
      lynis nchat neofetch ngrok postgresql_17_jit
      pritunl-client python312Packages.distutils quarto
      rbw redis slack solidtime-desktop
      ssm-session-manager-plugin teams-for-linux
      telegram-bot-api telegram-desktop terraform-docs
      terraform-ls yarn tfsec tfswitch typescript
      pkgs.unstable.zoom-us
      (texlive.combine {
        inherit (texlive) scheme-full datetime fmtcount textpos
          makecell lipsum footmisc background lato;
      })
      (python313.withPackages (ps: with ps; [
        jedi langchain langchain-community lxml pip pydub
        pyinstaller pylint python-dotenv pytz requests
        telegram-text tiktoken toggl-cli boto3
      ]))
    ];
  };
}
```

### Decision 4: lucak User Account

**Pattern**: Same structure as `casper/nixos.nix` and `antonia/nixos.nix`.

```nix
# modules/users/lucak/nixos.nix
{ inputs, self, ... }: {
  flake.modules.nixos.lucak = { pkgs, ... }: {
    users.users.lucak = {
      isNormalUser = true;
      description = "Luca Kasper (werk)";
      extraGroups = [ "networkmanager" "wheel" "docker" "disk" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtpGyC5u8+T71Oo+QL9ym+hWaNSiisskL43ElmpWiEr"
      ];
    };
  };
}
```

Same SSH key as casper — intentional for agenix secret sharing and GitHub access.

### Decision 5: Host Configuration Updates

Each host adds `lucak` to both NixOS and homeConfigurations:

```nix
# Example: gaming-casper/configuration.nix additions

flake.homeConfigurations = {
  "casper@${hostname}" = self.lib.makeHomeConf {
    inherit hostname;
    imports = with inputs.self.modules.homeManager; [ casper ];
  };
  "lucak@${hostname}" = self.lib.makeHomeConf {
    username = "lucak";
    homedir = "/home/lucak";
    inherit hostname;
    imports = with inputs.self.modules.homeManager; [ lucak ];
  };
};

# In NixOS module imports, add:
#   lucak          (user account)
# Remove from hosts that have it:
#   technative     (packages moved to shared-technative HM)
```

### Decision 6: Minimized technative.nix System Module

Only truly system-level config remains:

```nix
# modules/programs/work/technative.nix
{ inputs, unstable, ... }: {
  flake.modules.nixos.technative = { pkgs, ... }: {
    fonts.packages = with pkgs; [ lato ];
    security.acme = {
      defaults.email = "lucakasper8@gmail.com";
      acceptTerms = true;
    };
  };
}
```

Hosts that need `security.acme` (e.g., `technative-casper`) keep importing this. Hosts that don't need it (e.g., `gaming-casper`) can remove the import.

### Decision 7: Inactive Module Cleanup

Move to `modules/_unused/` (ignored by import-tree via `/_` path segment):

```
modules/_unused/
├── casper-hyprland-legacy/          ← hyprland.nix, hypridle.nix, hyprlock/, avizo.nix,
│                                       swaync.nix, walker.nix, waybar/, eww/, script.nix,
│                                       vogix.nix, default.nix
├── casper-themes/                   ← catppuccin/, gruvbox/
├── casper-gnome/                    ← gnome/default.nix
├── casper-kitty/                    ← kitty/default.nix
├── casper-ghostty/                  ← ghostty/default.nix
└── antonia-kde/                     ← kde/default.nix
```

### Decision 8: Hardcoded Path Fixes

**lucak-aws** (moved from casper-aws):
```nix
# Before:
technative_profiles = builtins.path {
  path = /home/casper/.aws/managed_service_accounts.json;
  name = "managed_service_accounts.json";
};

# After — use config.home.homeDirectory:
technative_profiles = builtins.path {
  path = /. + "${config.home.homeDirectory}/.aws/managed_service_accounts.json";
  name = "managed_service_accounts.json";
};
```

Note: `builtins.path` requires an absolute Nix path. Since `config.home.homeDirectory` is a string, we may need to use `builtins.toPath` or restructure to read from a known location. This needs testing during implementation.

**casper-nextcloud**:
```nix
# Before:
ExecStart = "... /home/casper/Documents ...";

# After:
ExecStart = "... ${config.home.homeDirectory}/Documents ...";
```

**shared-opencode**:
```nix
# Before:
plugin = [ "..." "/home/casper/git/personal/opencode-anthropic-login-via-cli" ];

# After:
plugin = [ "..." "${config.home.homeDirectory}/git/personal/opencode-anthropic-login-via-cli" ];
```

## Risks / Trade-offs

- **Module merge conflicts**: If shared and user modules set the same list attribute, it may duplicate entries. Use `lib.mkForce` sparingly, test merge behavior for `oh-my-zsh.plugins` specifically.
- **builtins.path with dynamic homeDirectory**: Nix's `builtins.path` evaluates at build time with pure paths. The `lucak-aws` module may need a different approach (e.g., reading from a fixed Nix store path or using `pkgs.writeText`). This is the highest-risk item.
- **Relative secret paths**: Modules using `../../../../../secrets/*.age` depend on file location. Moving `casper-aws` to `lucak/programs/aws/` changes the relative path depth — verify and fix.

## Open Questions

1. **oh-my-zsh plugins merge**: Does setting `programs.zsh.oh-my-zsh.plugins` in lucak fully override shared, or merge? If it overrides (which is the default for list options), lucak must include all plugins, not just the additions. Need to verify during implementation.
2. **builtins.path in lucak-aws**: Can we make the AWS managed accounts path dynamic? If not, lucak-aws may need to use the same hardcoded path with the lucak home directory, or use a symlink/shared location.
