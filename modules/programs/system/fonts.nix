{ inputs, ... }: {
  flake.modules.nixos.fonts = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.symbols-only
    ];
  };
}
