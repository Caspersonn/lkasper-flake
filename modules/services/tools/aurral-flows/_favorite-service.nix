{ pkgs }:
let
  source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/lklynet/aurral/3f01fa586f363f416f2e40c234a95550b87d74f7/backend/services/subsonicLibraryService.ts";
    sha256 = "0qb783ngc1agjcdkwdyxps50284kdh92fqcvvp786gm7kkkw47n2";
  };
in pkgs.runCommand "aurral-favorite-retention-2.13.0.ts" { nativeBuildInputs = [ pkgs.patch ]; } ''
  cp ${source} subsonicLibraryService.ts
  chmod u+w subsonicLibraryService.ts
  patch --fuzz=0 -p1 < ${./favorite-retention.patch}
  cp subsonicLibraryService.ts "$out"
''
