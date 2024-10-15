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

  python311Packages = prev.python311Packages // {
    toggl-cli = prev.python311Packages.toggl-cli.overrideAttrs (old: rec {
      version = "3.0.2";
      src = prev.fetchPypi {
        pname = "togglCli";
        inherit version;
        hash = "sha256-IGbd7Zgx1ovhHVheHJ1GXEYlhKxgpVRVmVpN2Xjn6mU="; # Vervang met de juiste SHA256-hash
      };
    });
  };

#jsonify-aws-dotfiles = prev.buildGoModule rec {
#    pname = "jsonify-aws-dotfiles";
#    version = "4c60e320b23ee0fae085cfce0b13d3753e39e73e";
#    src = prev.fetchgit {
#      url = "https://github.com/wearetechnative/jsonify-aws-dotfiles.git";
#      rev = "${version}";
#      hash = "sha256-sL1kpWyAVLxoQRJa+m7XSIaM0kxhmE1kOLpnTZVQwB0=";
#    };
#    vendorHash = "sha256-W6XVd68MS0ungMgam8jefYMVhyiN6/DB+bliFzs2rdk=";
#    nativeCheckInputs = with prev; [ less ];
#  };
}
