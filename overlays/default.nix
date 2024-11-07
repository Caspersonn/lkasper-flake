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
        hash = "sha256-IGbd7Zgx1ovhHVheHJ1GXEYlhKxgpVRVmVpN2Xjn6mU="; 
      };
    });
  };
}

