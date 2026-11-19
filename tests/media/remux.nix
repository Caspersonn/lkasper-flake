{ pkgs, agenix, media-storage, remux }:
let
  credential = pkgs.runCommand "remux-vm-credential" { nativeBuildInputs = [ pkgs.age ]; } ''
    mkdir -p "$out"
    age-keygen -o "$out/identity" 2>/dev/null
    echo '{"manifest_url":"https://fixture.invalid/manifest.json"}' |
      age --encrypt --recipient "$(age-keygen -y "$out/identity")" --output "$out/source.age"
  '';
  scripts = pkgs.runCommand "remux-vm-probe-imports" { } ''
    mkdir -p "$out"
    cp ${../../modules/services/tools/media-provision/remux.py} "$out/remux.py"
    cp ${../../modules/services/tools/media-provision/decypharr.py} "$out/decypharr.py"
  '';
in pkgs.testers.runNixOSTest {
  name = "remux-provision";
  nodes.machine = { lib, ... }: {
    imports = [ agenix.nixosModules.default media-storage remux ];
    age.identityPaths = [ "${credential}/identity" ];
    age.secrets.remux-aiostreams.file = lib.mkForce "${credential}/source.age";
    security.acme.acceptTerms = true;
    users.users.casper.isNormalUser = true;
    time.timeZone = "UTC";
    virtualisation.oci-containers.backend = "docker";
    virtualisation.memorySize = 3072;
    virtualisation.diskSize = 8192;
    systemd.services.remux-source-provision.wantedBy = lib.mkForce [ ];
    systemd.services.nginx.wantedBy = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.python3 ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("docker-remux-main.service", timeout=600)
    machine.succeed("python3 ${./remux-probe.py} ${scripts}")
    original = machine.succeed("sha256sum /var/lib/remux-provision/admin.json")
    machine.succeed("systemctl restart docker-remux-main.service", timeout=300)
    machine.succeed("python3 ${./remux-probe.py} ${scripts}")
    assert machine.succeed("sha256sum /var/lib/remux-provision/admin.json") == original
    machine.fail("systemctl start remux-source-provision.service", timeout=180)
    machine.succeed("test ! -e /run/remux-client/ready")
  '';
}
