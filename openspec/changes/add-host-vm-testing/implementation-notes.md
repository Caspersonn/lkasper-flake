# Implementation notes

## 1.1 Baseline (2026-11-12)

Real toplevel derivation paths before the change, stored outside the repo in `/tmp/vm-testing-baseline.txt`:

```
gaming-casper     /nix/store/kar7i0m3b65hzar9fjq7zgq7fnll39zv-nixos-system-gaming-casper-26.05.20261015.26f4107.drv
kaito             /nix/store/fg6jlivznbjvabi99x27mmiqsfrjd12n-nixos-system-kaito-26.05.20261015.26f4107.drv
personal-casper   /nix/store/1g6js5mgax9gzcfq1nb7vch2szamzq44-nixos-system-personal-casper-26.05.20261015.26f4107.drv
sakura            /nix/store/8zl47jmnksvfr0hcycfxnd9in7rdxl1z-nixos-system-sakura-26.05.20261015.26f4107.drv
technative-casper /nix/store/969i86riwb5011l31mmr27s73l657vjs-nixos-system-technative-casper-26.05.20261015.26f4107.drv
```

## 1.2 Pre-existing evaluation failure (neko, server-casper)

Both hosts fail to evaluate their real toplevel. This failure is unrelated to this change:

```
error:
       … while evaluating the option `services.nginx.virtualHosts."nextcloud.inspiravita.com".root':
       error: Refusing to evaluate package 'nextcloud-32.0.15' in /nix/store/c7w4dnzdyg31wrnx56y17wihi5zaibsl-source/pkgs/servers/nextcloud/default.nix:49 because it is marked as insecure
```

Their VMs (`vm-neko`, `vm-server-casper`) stay blocked until a separate change fixes this.

## 2.4 Outbound side effects not covered by the isolation set

Commands (run from the repo root, 2026-11-12):

```
grep -rnI --include='*.nix' -E 'ddclient|restic|borg|syncthing|rclone|OnCalendar|startAt|systemd\.timers|webhook|smtp|SMTP|sendmail|msmtp|postfix|telegram|discord|ntfy|pushover|healthchecks|s3://|wakeOnLan|dyndns|cloudflare|mqtt://|192\.168\.' modules/ | grep -v '^modules/users/'
grep -rnI --include='*.nix' -E 'systemd\.user\.(timers|services)|services\.(nextcloud-client|syncthing|rclone|unison)|OnCalendar|startAt|sync_address|auto_sync' modules/users/
```

| Finding | Effect in the VM | Action |
|---|---|---|
| `services/system/rtcwake.nix`: `rtcwake-hibernate` timer (neko) | Would hibernate the VM nightly | Disabled in the VM (task 3.1) |
| `services/networking/adguardhome.nix`: binds `192.168.2.94` and `10.100.0.1`, DHCP disabled, DoH upstreams | The bind addresses don't exist in the VM, so AdGuard Home can't serve DNS. Upstream queries are read-only internet traffic | None |
| `services/automation/home-assistant.nix`: MQTT on `127.0.0.1` | Integrations configured in the UI live in `/var/lib/hass`, which is empty in a fresh VM, so no real devices are controlled | None. The README warns that the VM can still reach LAN addresses through NAT |
| `services/security/smb.nix`: `hosts allow 192.168.178.` | Inbound only, and the VM is not reachable from the LAN | None |
| `programs/cli/tools.nix`: `borgbackup` | CLI package only, no backup jobs | None |
| `hardware/wol.nix`: `wakeOnLan` on the physical NIC, `wakeonlan` CLI | The NIC doesn't exist in the VM, and no job sends magic packets | None |
| `services/networking/wireguard.nix`: peer `10.0.0.2` | `networking.wg-quick.interfaces` is emptied by the isolation set | Already covered (task 2.2) |
| `users/shared/atuin.nix` (Home Manager): `auto_sync` to `https://atuin.inspiravita.com` | Sync only runs after `atuin login`. A fresh VM has no session or key, so nothing is synced | None. Home Manager stays identical to the real host |
| Docker containers (e.g. AIOStreams) | Pull images from public registries (read-only). AIOStreams fails without its agenix secret | None |

There were no matches for ddclient, restic, syncthing, rclone, SMTP or mail relays, webhooks, push services or S3 uploads. Only the rtcwake override was needed.

## 5.2–5.6 kaito VM results (2026-11-12)

Booted with `nix run .#vm-kaito -- --headless`; SSH answers after about 15–25 seconds.

- **5.2 Boot:** `systemctl is-system-running` reports `degraded`. Failed units are only secret-dependent or ACME:
  - `docker-aiostreams`: `--env-file /tmp/aiostreams-env` is missing.
  - `mosquitto`: credentials could not be set up.
  - `navidrome` and `vaultwarden`: environment files could not be loaded.
  - `acme-order-renew-aiostreams.inspiravita.com`: lego fails against `https://127.0.0.1:1/acme-disabled-in-vm`. The self-signed `acme-<domain>` units are active.
  - agenix fails to decrypt each secret but activation continues, so no skip-agenix fallback is needed.
- **5.3 Isolation:**
  - `ip -br link` shows only `lo`, `eth0` and `docker0`.
  - From the guest, `10.0.2.2:2222` is refused and ping to `10.0.2.2` fails.
  - `nixos.org:443` and DNS work.
  - On the workstation, QEMU listens only on `127.0.0.1:<port>`.
  - The REJECT counter grows only from connections the guest starts itself, for example systemd-resolved LLMNR to `10.0.2.2:5355` (UID 153) on each SSH login. It stays at +0 while idle, and no `INVALID` packets are rejected.
- **5.4 Access:**
  - The serial console logs in as `casper` automatically.
  - `sudo -n true` succeeds.
  - SSH with the existing key works.
  - With `--forward 8123:8123`, Home Assistant answers on `http://127.0.0.1:8123` with HTTP 302 (onboarding).
- **5.5 Persistence:**
  - A marker file survives a poweroff and restart.
  - `--reset` removes it: the image shrinks from 2.6 GB to 0.58 GB.
  - The image lives in `~/.local/state/lkasper-vms/kaito.qcow2`, and no `*.qcow2` or other new file appears in the repo.
- **5.6 Closure:**
  - Real toplevel and VM closures both contain 2544 paths.
  - 82 paths appear only in the VM: QEMU and its libraries, the VM run script and `closure-info`, VM-variant units and the system/etc derivations.
  - Real-only paths include `nebula`, `nebula-config-mesh.yml`, `tailscale` and `config-wgcasper`.
  - No VM-only path name matches secret/key/token/pass/env/cred.
  - The 21 `.age` files are identical in both closures and still encrypted.

### Fixes found during these tests

1. **Forwarded ports got no reply.** slirp delivers forwarded connections from `10.0.2.2`, so the first version of `vm-block-workstation` rejected sshd's replies; the symptom was "Connection timed out during banner exchange". Now only new connections are blocked: `ESTABLISHED,RELATED` traffic returns first, and the rule for routed traffic moved from the raw to the mangle table with `--ctstate NEW`.
2. **`~/.config` owned by root.** agenix creates the parent folders of home-folder secrets (`~/.config/jiratui`, `~/.config/soltty`) as root, so fish could not create its config folder and printed `mkdir: cannot create directory '/completions'`. The VM-only activation snippet `vmHomeConfigOwner` (after `users` and, when secrets exist, `agenix`) hands a root-owned `~/.config` back to its user.

Both fixes stay inside `virtualisation.vmVariant`. A re-run of task 5.1 after them still matches the baseline (`/tmp/vm-testing-after2.txt`).

## 6.1 and 6.3 Desktop host and two VMs at once (2026-11-12)

- `vm-kaito` (SSH 127.0.0.1:2222) and `vm-sakura -- --ssh-port 2223` ran side by side.
  The workstation only listened on `127.0.0.1:2222` and `127.0.0.1:2223`; each VM has
  its own user-mode NAT, so they cannot see each other.
- sakura reached `running` (not degraded). `loginctl` showed a `gdm-autologin` Wayland
  session for casper on seat0 with `gnome-shell --mode=user` running. A QMP
  `screendump` showed the GNOME overview, so the autologin works end to end.
- First build of `vm-sakura` took about 12 minutes (Steam, Lutris, Heroic, GNOME; all
  substituted from the cache, nothing compiled).

## 6.4 server-casper (blocked)

`nix eval .#apps.{x86_64,aarch64}-linux.vm-server-casper.program` both stop with the
pre-existing error from 1.2: `Refusing to evaluate package 'nextcloud-32.0.15' … marked
as insecure`. The launcher itself is wired up (the app exists on both systems); booting
under emulation can be tried once the nextcloud package in the `nextcloud` module is
upgraded or explicitly permitted. That fix is out of scope for this change.

## 6.2 Hyprland host (technative-casper, 2026-11-12)

- `nix run .#vm-technative-casper -- --headless` booted; the serial console logged
  casper in automatically.
- QEMU ran with `-vga none -device virtio-vga-gl,xres=1920,yres=1080`, and
  `--headless` added `-nographic -display egl-headless` after the GTK display.
- greetd started Hyprland 0.56.0 for casper: a `greetd` Wayland session on tty1, and
  `hyprctl monitors` showed `Virtual-1` at 1920x1080 on the virtio GPU. A `grim`
  screenshot showed the Hyprland desktop with its welcome window. QMP `screendump` does
  not work with `egl-headless` ("no surface"), so use `grim` inside the VM instead.
- Hyprland used its autogenerated config. casper's home-manager setup is a standalone
  `homeConfigurations."casper@<host>"`, not part of the NixOS system, so the VM doesn't
  get it (as the proposal already said). The README now says so.
- The only failed unit was `linny-mcp`. It binds
  `/home/casper/git/gh.caspersonn/lkasper-linny`, which doesn't exist in the VM, so this
  is the isolation working as intended. The README lists it.
