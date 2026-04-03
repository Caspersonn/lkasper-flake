{ inputs, self, ... }: {
  flake.modules.homeManager.casper = { pkgs, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      omarchy-themes
      omarchy-hyprland
      omarchy-walker
      omarchy-ghostty
      omarchy-waybar
      omarchy-wofi
      omarchy-mako
      omarchy-hyprlock
      #omarchy-hyprpaper
      omarchy-hyprshot
      omarchy-hypridle
      omarchy-btop
      omarchy-zsh
      omarchy-starship
      omarchy-direnv
      omarchy-fonts
      omarchy-zoxide

      # Shell programs
      casper-zsh
      casper-tmux
      casper-tses
      casper-atuin
      casper-fzf
      casper-zoxide
      casper-autojump
      casper-nextcloud

      ## Development
      casper-git
      casper-neovim


      ## Terminal
      #casper-kitty
      #casper-ghostty

      ## Browsers
      casper-firefox
      casper-librewolf


      ## Utilities
      casper-dirtygit
      casper-rbw
      casper-smug
      casper-opencode
      casper-jq
      casper-font
      casper-aws
      casper-age

    ]);

    omarchy = {
      scale = 1;
    };

    nixpkgs.config.allowUnfree = true;

  };
}
