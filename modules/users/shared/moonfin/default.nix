{ ... }:
{
  flake.modules.homeManager.shared-moonfin = { pkgs, ... }: {
    home.packages = [ (pkgs.callPackage ./_package.nix { }) ];
  };
}
