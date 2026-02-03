{ inputs, ... }: {
  flake.modules.nixos.docker-stremio = { config, pkgs, ... }: {
    #let
    #  networkName = "docker-stremio_server";
    #
    #in
    #{
    #  system.activationScripts.docker-stremio_server =
    #  let
    #    backend = config.virtualisation.oci-containers.backend;
    #    backendBin = "${pkgs.${backend}}/bin/${backend}";
    #  in
    #    ''
    #    ${backendBin} network inspect ${networkName} >/dev/null 2>&1 || \
    #    ${backendBin} network create --driver bridge ${networkName}
    #  '';
    #
    #
    #  virtualisation.oci-containers.containers."stremio-server" =
    #  {
    #    image = "stremio/server:latest";
    #    ports = [ "11470:11470" "12470:12470" ];
    #    environment = {  };
    #    dependsOn = [ ];
    #    volumes = [
    #    "/bin/ffmpeg:/bin/ffmpeg:ro"
    #    "/bin/ffprobe:/bin/ffprobe:ro"
    #    ];
    #    extraOptions = [ "--network=${networkName}" ];
    #  };
    #
    ##  services.nginx.virtualHosts."server-casper.com" = {
    ##    enableACME = true;
    ##    forceSSL = true;
    ##    locations = {
    ##     "/" = {
    ##        proxyPass = "http://127.0.0.1:11470" "https://127.0.0.1:12470"  ;
    ##      };
    ##    };
    ##  };
    #  nixpkgs.config.packageOverrides = pkgs: {
    #    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    #  };
    #  hardware.opengl = { # hardware.graphics on unstable
    #    enable = true;
    #    extraPackages = with pkgs; [
    #      intel-media-driver # LIBVA_DRIVER_NAME=iHD
    #      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
    #      libvdpau-va-gl
    #    ];
    #  };
    #  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver
    #}
  };
}
