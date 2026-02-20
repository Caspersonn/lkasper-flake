{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.whitesur-cursors = pkgs.stdenv.mkDerivation rec {
      pname = "whitesur-cursors";
      version = "2024-06-02";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "WhiteSur-cursors";
        rev = version;
        sha256 = "sha256-0000000000000000000000000000000000000000000=";
      };
      installPhase = ''
        mkdir -p $out/share/icons
        ./install.sh -d $out/share/icons
      '';
    };
  };
}
