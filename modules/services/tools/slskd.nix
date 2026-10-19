{ ... }:
{
  # Soulseek client, used by Aurral as its download source.
  flake.modules.nixos.slskd = { config, ... }:
    let
      slskdDir = "/mnt/audio/slskd";
    in
    {
      # SLSKD_SLSK_USERNAME/PASSWORD, SLSKD_USERNAME/PASSWORD, SLSKD_API_KEY.
      age.secrets.music-slskd.file = ../../../secrets/music-slskd.age;

      services.slskd = {
        enable = true;
        # Soulseek peer port (50300); forward it on the router for best speeds.
        openFirewall = true;
        domain = null;
        environmentFile = config.age.secrets.music-slskd.path;
        settings = {
          directories = {
            downloads = "${slskdDir}/downloads";
            incomplete = "${slskdDir}/incomplete";
          };
          # Sharing keeps peers from blocking us as a leecher.
          shares.directories = [ "/mnt/audio/music" ];
        };
      };

      # Aurral moves finished downloads out of slskd's folder: group-writable.
      systemd.services.slskd.serviceConfig.UMask = "0002";

      systemd.tmpfiles.settings = {
        # Shared parent must be root-owned, otherwise tmpfiles refuses to create
        # the service-owned folders below it ("unsafe path transition").
        "10-audio-root"."/mnt/audio".d = { user = "root"; group = "root"; mode = "0755"; };
        "10-slskd" = {
          ${slskdDir}.d = { user = "slskd"; group = "slskd"; mode = "2770"; };
          "${slskdDir}/downloads".d = { user = "slskd"; group = "slskd"; mode = "2770"; };
          "${slskdDir}/incomplete".d = { user = "slskd"; group = "slskd"; mode = "2770"; };
        };
      };
    };
}
