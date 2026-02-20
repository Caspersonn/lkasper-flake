{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.whitesur-cursors = pkgs.stdenv.mkDerivation {
      pname = "whitesur-cursors";
      version = "e190baf";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "WhiteSur-cursors";
        rev = "e190baf618ed95ee217d2fd45589bd309b37672b";
        sha256 = "sha256-hFtfq8F6KeqUEBlypPCr/EKq6rif/g868vJd8c06c1I=";
      };
      installPhase = ''
        mkdir -p $out/share/icons/WhiteSur-cursors
        cp -pr dist/* $out/share/icons/WhiteSur-cursors/
      '';
    };
  };
}
