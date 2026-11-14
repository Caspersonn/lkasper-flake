# Implementation notes: add-holyarrs

## Group 1 (pre-flight on kaito): blocked (2026-11-12)

kaito was unreachable while this change was implemented: `ping 10.123.0.1`
lost every packet, Nebula handshakes to `77.175.230.128:4242` timed out and
the public vhosts did not answer. Tasks 1.1–1.3 stay open and must be done
before task 7.1. The configuration itself was checked instead:

- Nebula network `mesh` without `tun.device`, so the interface is `nebula.mesh`.
- `services.tailscale.interfaceName` is `tailscale0`.
- No user or group in kaito's configuration declares uid/gid 2000.
- No tmpfiles rule for `/data` exists yet.

## 6.1–6.3 Build and diff (2026-11-12)

- kaito toplevel built: `/nix/store/lvr3q4vajyfqz28251jh8r043qgc9p7x-nixos-system-kaito-26.05.20261015.26f4107`
  (only Jackett and the .NET runtime were fetched; nothing was compiled).
- The toplevel derivations of gaming-casper, personal-casper, sakura and
  technative-casper are identical before and after; only kaito changed.
- The diff adds no tokens, passwords or API keys and no `.age` file.

## Smoke test in the kaito test VM (2026-11-12)

Not a task in this change, but kaito was down and the project rule is to test
on a non-critical machine first. `nix run .#vm-kaito -- --reset --headless
--forward 6262:6262` (see the add-host-vm-testing change):

- `docker-decypharr`, `docker-holyarrs` and `jackett` all `active`; both
  containers `healthy` after pulling their images (about three minutes on a
  fresh disk). The only failed units were the expected secret/ACME ones.
- `media` is uid/gid 2000, casper is in group `media`. `/data` is root 0755,
  `/data/debrid` root 0755 (mount point), the other folders `media:media`
  `drwxrws---`.
- `docker inspect`: host network for both; Decypharr has `CAP_SYS_ADMIN`,
  `apparmor=unconfined`, `/dev/fuse` and `/data` `rshared`; HolyArrs has no
  extra capabilities and `/data` `rslave`.
- `holyarrs doctor`: 14 OK, 0 WARN, 0 FAIL (runs as 2000:2000, umask 0002,
  `/data/symlinks` writable, metadata server reachable).
- HolyArrs keeps its master key at **`/var/lib/holyarrs/holyarrs.key`** (the
  `/config` root), which is the file task 8.5 must back up.
- Decypharr writes a default `config.json` and `auth.json` on first start and
  sends `/` to `/setup`, so the wizard of task 8.1 is still shown.
- Mount propagation: a tmpfs mounted inside the Decypharr container at
  `/data/debrid` was visible on the host and inside HolyArrs' mount namespace
  (read through `/proc/<pid>/root`). After `systemctl restart
  docker-decypharr` the `ExecStopPost` lazy unmount removed it from both;
  `ExecStartPre` then reported "not mounted".
- Firewall: the forwarded port arrives on the VM's `eth0` and timed out from
  the workstation, so 6262 is closed outside the mesh interfaces even with
  `--network=host`. The `nixos-fw` chain only accepts 6262, 8282 and 9117 on
  `nebula.mesh` and `tailscale0`.
- `HOLYARRS_ALLOWED_HOSTS` could not be proven from inside the VM: requests
  from 127.0.0.1 were answered for any `Host` header (also `evil.example`).
  Task 7.3 covers it with a real mesh request to `http://kaito.mesh:6262`.
- HolyArrs logged "TMDB: Metadata server is down … context deadline exceeded"
  every two seconds for its Explore lists while `doctor` reported the
  metadata server reachable. This is on the HolyArrs side, not in this
  configuration; check whether it persists on kaito.
