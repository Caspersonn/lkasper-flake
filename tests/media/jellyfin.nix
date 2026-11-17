{ pkgs, media-storage, jellyfin }:
pkgs.testers.runNixOSTest {
  name = "jellyfin-provision";
  nodes.machine = { lib, ... }: {
    imports = [ media-storage jellyfin ];
    security.acme.acceptTerms = true;
    users.users.casper = {
      isNormalUser = true;
      group = "users";
    };
    time.timeZone = "UTC";
    system.switch.enable = true;
    virtualisation.memorySize = 3072;
    virtualisation.diskSize = 4096;
    systemd.services.nginx.wantedBy = lib.mkForce [ ];
    systemd.services.holyarrs-fixture = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${./moonfin/holyarrs-fixture.py}";
    };
    systemd.services.jellyfin = {
      after = [ "holyarrs-fixture.service" ];
      environment.MOONFIN_HOLYARRS_KEY_FILE = "%d/holyarrs-key";
      serviceConfig.LoadCredential = [
        "holyarrs-key:${pkgs.writeText "moonfin-test-key" ''{"key":"moonfin-fixture-secret"}''}"
      ];
    };
    systemd.services.moonfin-video-fixture = {
      wantedBy = [ "multi-user.target" ];
      before = [ "jellyfin.service" ];
      requiredBy = [ "jellyfin.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        install -d -m 0755 /data/debrid/fixture "/data/media/movies/Fixture Movie (2000)"
        ${pkgs.ffmpeg}/bin/ffmpeg -loglevel error -f lavfi -i color=c=black:s=160x90:d=1 -c:v libx264 -y /data/debrid/fixture/movie.mkv
        ln -sfn /data/debrid/fixture/movie.mkv "/data/media/movies/Fixture Movie (2000)/Fixture Movie (2000).mkv"
        printf '%s' '<movie><title>Fixture Movie</title><year>2000</year><tmdbid>551</tmdbid><uniqueid type="tmdb" default="true">551</uniqueid></movie>' > "/data/media/movies/Fixture Movie (2000)/movie.nfo"
      '';
    };
    environment.systemPackages = [ pkgs.python3 ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("jellyfin-media-provision.service")
    machine.succeed("python3 ${./jellyfin-probe.py}")
    original = machine.succeed("sha256sum /var/lib/jellyfin/provision/admin.json")
    machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
    machine.wait_for_unit("jellyfin-media-provision.service")
    machine.succeed("python3 ${./jellyfin-probe.py}")
    assert machine.succeed("sha256sum /var/lib/jellyfin/provision/admin.json") == original
    assert machine.succeed("stat -c %a /var/lib/jellyfin/provision/admin.json").strip() == "600"
  '';
}
