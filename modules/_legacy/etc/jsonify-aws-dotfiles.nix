{ config, pkgs }:

let
  pname = "jsonify-aws-dotfiles";
  version = "0.1.0"; # Je kunt deze versie aanpassen naar wat er in de repository is gedefinieerd.
in pkgs.stdenv.mkDerivation rec {
  pname = pname;
  version = version;

  src = pkgs.fetchFromGitHub {
    owner = "niko-dunixi";
    repo = pname;
    rev = "HEAD"; # Je kunt een specifieke commit hash of tag opgeven als je niet HEAD wilt gebruiken.
    sha256 = "sha256-i9V0LUWJ1uiRSwZnFPanrY1aoie+n3vEmQ8030Lwq84="; # Vervang dit door de echte SHA-256 hash na het bouwen.
  };

  nativeBuildInputs = [ pkgs.go ];

  goPackagePath = "github.com/niko-dunixi/${pname}";

  buildPhase = ''
    export GOPATH=$(mktemp -d)
    mkdir -p $GOPATH/src/github.com/niko-dunixi/
    cp -r $src $GOPATH/src/github.com/niko-dunixi/${pname}
    cd $GOPATH/src/github.com/niko-dunixi/${pname}
    go build
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${pname} $out/bin/
  '';

  meta = with lib; {
    description = "A Go module for converting AWS dotfiles to JSON format.";
    homepage = "https://github.com/niko-dunixi/${pname}";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
