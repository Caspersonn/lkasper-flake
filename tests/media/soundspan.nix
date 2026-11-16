{ pkgs, media-storage, holyarrs, soundspan, postgres }:
pkgs.testers.runNixOSTest {
  name = "soundspan-provision";
  nodes.machine = { lib, ... }: {
    imports = [ postgres media-storage holyarrs soundspan ];
    security.acme.acceptTerms = true;
    users.users.casper = {
      isNormalUser = true;
      group = "users";
    };
    time.timeZone = "UTC";
    system.switch.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.memorySize = 4096;
    virtualisation.diskSize = 8192;
    systemd.services.nginx.wantedBy = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.python3 ];
    systemd.services.soundspan-linked-fixture = {
      requiredBy = [ "soundspan-backend.service" ];
      before = [ "soundspan-backend.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      script = ''
        mkdir -p /data/debrid/fixture /data/media/music/Fixture
        ${pkgs.ffmpeg}/bin/ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 -metadata artist="Linked Artist" -metadata album="Linked Album" -metadata title="Linked Track" /data/debrid/fixture/track.flac
        ln -s /data/debrid/fixture/track.flac /data/media/music/Fixture/track.flac
      '';
    };
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("soundspan-provision.service")
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:3030/ >&2")
    machine.succeed("curl -fsS -D - -o /dev/null -H 'Origin: https://soundspan.inspiravita.com' http://127.0.0.1:3006/api/onboarding/status | grep -i 'access-control-allow-origin: https://soundspan.inspiravita.com'")
    machine.succeed("runuser -u soundspan -- test -w /var/cache/soundspan/transcodes")
    machine.succeed("python3 ${./soundspan-probe.py}")
    machine.wait_until_succeeds("runuser -u postgres -- psql soundspan -tAc 'SELECT count(*) FROM \"Track\"' | grep -x '1'")
    machine.succeed("runuser -u soundspan -- test -w /var/log/soundspan/playlists")
    original = machine.succeed("sha256sum /var/lib/soundspan/provision/admin.json")
    machine.succeed("/run/current-system/bin/switch-to-configuration test >&2")
    machine.wait_for_unit("soundspan-provision.service")
    machine.succeed("curl -fsS -D - -o /dev/null -H 'Origin: https://soundspan.inspiravita.com' http://127.0.0.1:3006/api/onboarding/status | grep -i 'access-control-allow-origin: https://soundspan.inspiravita.com'")
    machine.succeed("runuser -u soundspan -- test -w /var/cache/soundspan/transcodes")
    machine.succeed("python3 ${./soundspan-probe.py}")
    assert machine.succeed("sha256sum /var/lib/soundspan/provision/admin.json") == original
    assert machine.succeed("stat -c %a /var/lib/soundspan/provision/admin.json").strip() == "600"
    machine.succeed("! grep -F \"$(cat /var/lib/soundspan/provision/admin.json)\" /etc/systemd/system /run/current-system 2>/dev/null || true")
  '';
}
