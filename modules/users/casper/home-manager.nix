{ inputs, self, ... }: {
  flake.modules.homeManager.casper = {

    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      omarchy-themes
      omarchy-hyprland
      omarchy-ghostty
      omarchy-waybar
      omarchy-wofi
      omarchy-mako
      omarchy-hyprlock
      omarchy-hyprpaper
      omarchy-hypridle
      omarchy-btop
      omarchy-git
      omarchy-zsh
      omarchy-starship
      omarchy-direnv
      omarchy-fonts
      omarchy-vscode
      omarchy-zoxide

      # Shell programs
      casper-zsh
      casper-tmux
      casper-atuin
      casper-fzf
      casper-zoxide
      casper-autojump
      casper-nextcloud

      ## Development
      #casper-git
      casper-neovim

      ## Desktop
      #casper-hyprland
      #hypridle
      #hyprlock
      #scripts
      #hyprland
      #walker
      #waybar
      #eww
      #swaync
      #vogix
      #avizo

      ## Terminal
      casper-kitty
      casper-ghostty

      ## Browsers
      casper-firefox
      casper-librewolf

      ## Media
      #casper-vesktop
      ## casper-retroarch  # TODO: Fix pkgs argument passing

      ## Utilities
      casper-dirtygit
      casper-rbw
      casper-smug
      casper-opencode
      casper-jq
      casper-font
      casper-aws
      casper-age

      ## Theme
      #casper-gruvbox
    ]);

    omarchy = {
      full_name = "caspersonn";
      email_address = "lucakasper8@gmail.com";
      theme = "gruvbox";
      scale = 1;
    };

    nixpkgs.config.allowUnfree = true;

  };
}
