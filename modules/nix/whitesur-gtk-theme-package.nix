{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.whitesur-gtk-theme = pkgs.stdenv.mkDerivation rec {
      pname = "whitesur-gtk-theme";
      version = "2025-07-24";
      src = pkgs.fetchFromGitHub {
        owner = "vinceliuice";
        repo = "WhiteSur-gtk-theme";
        rev = version;
        sha256 = "sha256-tuon9XxMdrz9XNTp50sbss2gtx6H9hEZh8t2jSoqx28=";
      };
      nativeBuildInputs = with pkgs; [ sassc which coreutils util-linux libxml2 ];
      buildInputs = with pkgs; [ glib ];
      patchPhase = ''
        patchShebangs install.sh
        patchShebangs tweaks.sh
        substituteInPlace libs/lib-core.sh \
          --replace 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME=$HOME'
        substituteInPlace libs/lib-core.sh \
          --replace 'prompt -i "\n DEPS: Checking your internet connection..."' 'true' \
          --replace 'if ping -q -c 1 -W 1 8.8.8.8' 'if true'
        echo '#!/bin/sh' > /tmp/sudo
        echo 'exec "$@"' >> /tmp/sudo
        chmod +x /tmp/sudo
      '';
      installPhase = ''
        mkdir -p $out/share/themes
        HOME=$TMPDIR PATH=/tmp:$PATH ./install.sh -d $out/share/themes -c Dark -t default -N glassy
      '';
    };
  };
}
