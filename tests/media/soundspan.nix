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
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("soundspan-provision.service")
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:3030/ >&2")
    machine.succeed("curl -fsS -D - -o /dev/null -H 'Origin: https://soundspan.inspiravita.com' http://127.0.0.1:3006/api/onboarding/status | grep -i 'access-control-allow-origin: https://soundspan.inspiravita.com'")
    machine.succeed("runuser -u soundspan -- test -w /var/cache/soundspan/transcodes")
    machine.succeed("python3 ${./soundspan-probe.py}")
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
