{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.whitesur-icon-theme = pkgs.stdenv.mkDerivation rec {
      pname = "whitesur-icon-theme";
      version = "v2025-02-10";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "WhiteSur-icon-theme";
        rev = version;
        sha256 = "sha256-spTmS9Cn/HAnbgf6HppwME63cxWEbcKwWYMMj8ajFyY=";
      };
      nativeBuildInputs = with pkgs; [ gtk3 ];
      patchPhase = ''
        patchShebangs install.sh
      '';
      installPhase = ''
        mkdir -p $out/share/icons
        ./install.sh -d $out/share/icons -t default -a
      '';
    };
  };
}
