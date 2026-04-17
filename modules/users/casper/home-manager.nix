{ inputs, self, ... }: {
  flake.modules.homeManager.casper = { pkgs, ... }: {
    imports = with inputs.self.modules.homeManager; (with inputs.omarchy-nix.homeManagerModules; [
      lkh-themes
      lkh-ags
      lkh-hyprland
      lkh-ghostty
      lkh-hyprlock
      lkh-hyprpaper
      lkh-hypridle
      lkh-btop
      lkh-zsh
      lkh-starship
      lkh-direnv
      lkh-fonts
      lkh-zoxide
      lkh-hyprshot


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
      casper-dirty-repo-scanner
      casper-rbw
      casper-smug
      casper-opencode
      casper-jq
      casper-font
      casper-aws
      casper-age

    ]);


    nixpkgs.config.allowUnfree = true;

  };
}
