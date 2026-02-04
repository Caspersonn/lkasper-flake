{ inputs, self, ... }: {
  flake.modules.homeManager.casper = {
    imports = with inputs.self.modules.homeManager; [
      # Shell programs
      casper-zsh
      casper-tmux
      casper-atuin
      casper-fzf
      casper-zoxide
      casper-autojump

      hypridle
      hyprlock
      scripts
      hyprland
      walker
      waybar
      eww
      swaync
      vogix
      avizo

      ## Development
      casper-git
      casper-neovim

      ## Desktop - TEMPORARILY DISABLED
      ## TODO: Fix waybar configuration structure
      casper-hyprland
      ##casper-gnome

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
      casper-aws  # TODO: Fix home attribute missing error

      ## Theme (choose one)
      casper-gruvbox
      # casper-catppuccin
    ];

    nixpkgs.config.allowUnfree = true;
  };
}
