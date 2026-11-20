{ pkgs }:
let
  source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lklynet/aurral/4b3708a89753e61115d8353a0a68086deb8d6417/backend/services/subsonicLibraryService.ts";
    sha256 = "58a05938d0473740390261c06b175c7c2b4af64cf0bdb49fe8d2a1df82e611b2";
  };
in pkgs.runCommand "aurral-favorite-retention-nightly-4b3708a.ts" { nativeBuildInputs = [ pkgs.patch ]; } ''
  cp ${source} subsonicLibraryService.ts
  chmod u+w subsonicLibraryService.ts
  patch --fuzz=0 -p1 < ${./favorite-retention.patch}
  cp subsonicLibraryService.ts "$out"
''
