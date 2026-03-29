{ inputs, ... }: {
  flake.modules.nixos.dev-android = { unstable, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      android-tools
      scrcpy
    ];
  };
}
