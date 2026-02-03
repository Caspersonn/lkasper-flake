{inputs, ...}: {
  # Helper function to import nixpkgs with overlays for a specific system
  flake.lib.importFromChannelForSystem = system: channel:
    import channel {
      overlays = [
        (import ../overlays)
      ];
      inherit system;
      config.allowUnfree = true;
    };
}
