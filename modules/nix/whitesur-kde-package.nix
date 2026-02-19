{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.whitesur-kde = pkgs.stdenv.mkDerivation rec {
      pname = "whitesur-kde";
      version = "2024-11-18";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "WhiteSur-kde";
        rev = "2024-11-18";
        sha256 = "sha256-052mKpf8e5pSecMzaWB3McOZ/uAqp/XGJjcVWnlKPLE=";
      };
      installPhase = ''
        mkdir -p $out/share
        cp -r aurorae $out/share/ || true
        cp -r color-schemes $out/share/ || true
        cp -r plasma $out/share/ || true
        cp -r Kvantum $out/share/ || true
        cp -r latte-dock $out/share/ || true
      '';
    };
  };
}
