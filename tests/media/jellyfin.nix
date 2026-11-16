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
