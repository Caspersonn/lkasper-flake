{ inputs, ... }: {
  flake.modules.nixos.dev-ai = { unstable, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      inputs.teejay.packages."${pkgs.stdenv.hostPlatform.system}".default
      inputs.specgetty.packages."${pkgs.stdenv.hostPlatform.system}".default

      claude-code
      # opencode  # Configuration is in home-manager
      claude-monitor
      pkgs.unstable.rtk
    ];
  };
}
