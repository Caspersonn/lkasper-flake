{ inputs, ... }: {
  flake.modules.nixos.dev-languages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      inputs.openspec.packages."${pkgs.stdenv.hostPlatform.system}".default

      # Build Tools
      gcc
      gnumake42

      # Languages
      go
      ruby
      nodejs_24
      cargo
      rustc

      # Nix Tools
      home-manager
      node2nix
      pre-commit

      # Other
      hugo
      claude-code

      # Python with packages
      (python313.withPackages (ps: with ps; [ openpyxl tkinter sv-ttk ]))
    ];
  };
}
