{ withSystem, ... }: {
  flake.overlays.apps = final: prev:
    withSystem prev.stdenv.hostPlatform.system (

      # perSystem parameters. Note that perSystem does not use `final` or `prev`.
      { config, ... }: {
        quarto = prev.quarto.override {
          extraPythonPackages = ps: with ps; [
            numpy
            pandas
            matplotlib
            tabulate
          ];
        };

        #bambu-studio = prev.bambu-studio.overrideAttrs (oldAttrs: {
        #  version = "01.00.01.50";
        #  src = prev.fetchFromGitHub {
        #    owner = "bambulab";
        #    repo = "BambuStudio";
        #    rev = "v01.00.01.50";
        #    hash = "sha256-7mkrPl2CQSfc1lRjl1ilwxdYcK5iRU//QGKmdCicK30=";
        #  };
        #});
        #  mutter = prev.mutter.overrideAttrs (old: {
        #    src = prev.fetchFromGitLab  {
        #      domain = "gitlab.gnome.org";
        #      owner = "vanvugt";
        #      repo = "mutter";
        #      rev = "triple-buffering-v4-46";
        #      hash = "sha256-C2VfW3ThPEZ37YkX7ejlyumLnWa9oij333d5c4yfZxc=";
        #    };
        #  });
        python311Packages = prev.python311Packages // {
          toggl-cli = prev.python311Packages.toggl-cli.overrideAttrs (old: rec {
            version = "3.0.2";
            src = prev.fetchPypi {
              pname = "togglCli";
              inherit version;
              hash = "sha256-IGbd7Zgx1ovhHVheHJ1GXEYlhKxgpVRVmVpN2Xjn6mU="; 
            };
          });
        };
        matterbridge = prev.buildGoModule rec {
          name = "matterbridge";
          src = prev.fetchFromGitHub {
            owner = "technative-B-V";
            repo = "matterbridge";
            rev = "master";
            sha256 = "sha256-4FQapL44kx334I6W0rdpzarz/Dm4oz5uqVb05dJzY0s=";
          };
          vendorHash = null;
        };
        #  pname = "matterbridge";
        #  src = prev.fetchgit {
        #    url = "https://github.com/TechNative-B-V/matterbridge.git";
        #    rev = "master";
        #    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        #  };
        #  vendorHash = null;
        #};
        #cypress = prev.cypress.overrideAttrs (oldAttrs: rec {
        #   pname = "cypress";
        #   version = "13.16.0";
        #   src = prev.fetchzip {
        #     url = "https://cdn.cypress.io/desktop/${version}/linux-x64/cypress.zip";
        #     sha256 = "sha256-D1pzxq7yNzSDA1ZNYfdJVz3vLare/y8IbC7tN5tAff4=";
        #   };
        # });
        #wivrn = prev.wivrn.overrideAttrs (old: {
        #  version = "25.05";
        #  src = prev.fetchFromGitHub {
        #    owner = "wivrn";
        #    repo = "wivrn";
        #    rev = "v${old.version}";
        #    hash = "sha256-XP0bpXgtira2QIlS0fNEteNP48WnEjBYFM1Xmt2sm5I=";
        #  };
        #});
      });
}

