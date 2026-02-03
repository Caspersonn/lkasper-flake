{ inputs, ... }: {
  flake.modules.nixos.server-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      acme-sh
      openssl
      invidious
      stremio
    ];
  };
}
