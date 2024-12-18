final: prev: {
  quarto = prev.quarto.override {
    extraPythonPackages = ps: with ps; [
      plotly
      numpy
      pandas
      matplotlib
      tabulate
    ];
  };
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
    pname = "matterbridge";
    version = "5b86262fddabf5536faec4e4e4b1f6a9329fa635";
    #src = pkgs.fetchFromGitHub {
    #  owner = "wearetechnative";
    #  repo = "jsonify-aws-dotfiles";
    #  rev = "${version}";
    #  sha256 = "sha256-sL1kpWyAVLxoQRJa+m7XSIaM0kxhmE1kOLpnTZVQwB0=";
    #};
    src = prev.fetchgit {
      url = "https://github.com/kolsys/matterbridge.git";
      rev = "${version}";
      hash = "sha256-4OJs8VOkRnuUw922/C/6C0sWyphRZ9Dn0dmKOPrzrk8=";
    };
    vendorHash = null;
    #nativeCheckInputs = with pkgs; [ less ];
  };
 cypress = prev.cypress.overrideAttrs (oldAttrs: rec {
    pname = "cypress";
    version = "13.16.0";
    src = prev.fetchzip {
      url = "https://cdn.cypress.io/desktop/${version}/linux-x64/cypress.zip";
      sha256 = "sha256-D1pzxq7yNzSDA1ZNYfdJVz3vLare/y8IbC7tN5tAff4=";
    };
  });
}

