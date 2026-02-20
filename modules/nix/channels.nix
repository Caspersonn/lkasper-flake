{ inputs, ... }:

{
  flake.modules.nixos.nix-channels =
    let
      initChannel = channel: final:
        import channel { inherit (final) config system; };
    in
    {
      nixpkgs.overlays = [

        inputs.self.overlays.apps
        inputs.nix-cachyos-kernel.overlays.pinned

        (final: _prev: {
          unstable = initChannel inputs.unstable final;
        })

      ];
    };
}
