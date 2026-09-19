{ withSystem, ... }: {
  flake.overlays.apps = final: prev:
    withSystem prev.stdenv.hostPlatform.system (

      # perSystem parameters. Note that perSystem does not use `final` or `prev`.
      { config, ... }:
      let
        bambuStudioSrc = prev.fetchFromGitHub {
          owner = "mindrunner";
          repo = "BambuStudio";
          rev = "a8beca80b5c60713de9a62c9e270dcc7100550dc";
          hash = "sha256-vBPvbZ8WOflCzp1qxHWHMxtUSCl5ZBjQf6IgEOBE06c=";
        };

        # The fork's GUI/DeviceWeb adds a React/Vite frontend built via a
        # vendored Node.js + pnpm that it downloads and runs `pnpm install`
        # against the npm registry at CMake configure time. That needs
        # network access, which nixpkgs' sandboxed build doesn't have, so
        # it's built here as its own derivation (vendored via
        # fetchPnpmDeps) and copied in by device-page-prebuilt.patch instead.
        bambuStudioDevicePageDeps = prev.fetchPnpmDeps {
          pname = "bambu-studio-device-page";
          version = "0.0.0";
          src = "${bambuStudioSrc}/src/slic3r/GUI/DeviceWeb/device_page";
          pnpm = prev.pnpm_10;
          fetcherVersion = 4;
          hash = "sha256-4hpdGeC+SQgGZl0M6KI7Del2TErIU/T6cuza7/GNUE0=";
        };
      in
      {
        bambu-studio-device-page = prev.stdenv.mkDerivation {
          pname = "bambu-studio-device-page";
          version = "0.0.0";
          src = "${bambuStudioSrc}/src/slic3r/GUI/DeviceWeb/device_page";
          nativeBuildInputs = [
            prev.nodejs_22
            prev.pnpm_10
            prev.pnpmConfigHook
          ];
          pnpmDeps = bambuStudioDevicePageDeps;
          buildPhase = ''
            runHook preBuild
            pnpm run build
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r dist/. $out/
            runHook postInstall
          '';
        };

        quarto = prev.quarto.override {
          extraPythonPackages = ps: with ps; [
            numpy
            pandas
            matplotlib
            tabulate
          ];
        };


        bambu-studio-libnoise = prev.stdenv.mkDerivation {
          pname = "bambu-studio-libnoise";
          version = "unstable-2026-08-24";
          src = prev.fetchFromGitHub {
            owner = "bambulab";
            repo = "libnoise";
            rev = "7e7c98c06a67d5203dd780b45e9a25d3ec930fd8";
            hash = "sha256-9uSTnlKFe1ck9R0vNVLzWHxJlsi8rKFR+nIec4naikY=";
          };
          nativeBuildInputs = [ prev.cmake ];
          cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
        };

        bambu-studio = prev.bambu-studio.overrideAttrs (oldAttrs: {
          version = "linux-wayland-support-a8beca8";
          src = bambuStudioSrc;
          # Upstream nixpkgs patches were written against bambulab/BambuStudio and
          # don't apply cleanly to this fork's tree (rebased on a much newer
          # upstream). Re-forked here against the fork's actual line numbers.
          # cmake.patch is dropped: the fork already sets
          # CMAKE_POLICY_VERSION_MINIMUM in its top-level CMakeLists.txt.
          patches = [
            ./patches/bambu-studio/0001-not-for-upstream-CMakeLists-Link-against-webkit2gtk-.patch
            ./patches/bambu-studio/dont-link-opencv-world-bambu.patch
            ./patches/bambu-studio/no-osmesa.patch
            ./patches/bambu-studio/no-cereal.patch
            ./patches/bambu-studio/device-page-prebuilt.patch
          ];
          buildInputs = oldAttrs.buildInputs ++ [ final.bambu-studio-libnoise prev.assimp prev.libharu ];
          cmakeFlags = oldAttrs.cmakeFlags ++ [
            # Findlibnoise.cmake searches PATHS ${CMAKE_PREFIX_PATH} with
            # NO_DEFAULT_PATH, which skips the NIXPKGS_CMAKE_PREFIX_PATH nixpkgs'
            # cmake normally relies on for buildInputs discovery. Point it at
            # the libnoise output explicitly.
            (prev.lib.cmakeFeature "CMAKE_PREFIX_PATH" "${final.bambu-studio-libnoise}")
            (prev.lib.cmakeFeature "BAMBU_STUDIO_DEVICE_PAGE_DIST" "${final.bambu-studio-device-page}")
          ];
        });
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

