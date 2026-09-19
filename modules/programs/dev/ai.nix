{ inputs, ... }: {
  flake.modules.nixos.dev-ai = { unstable, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      inputs.teejay.packages."${pkgs.system}".default
      inputs.specgetty.packages."${pkgs.system}".default
      #inputs.openlore.packages."${pkgs.system}".default

      # opencode  # Configuration is in home-manager
      claude-monitor
      pkgs.unstable.rtk
      beans
    ];
  };
}
