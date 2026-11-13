# Tasks

## 1. Baseline

- [x] 1.1 Record the real toplevel derivation paths of kaito, sakura, technative-casper, gaming-casper and personal-casper (`nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`) into a file outside the repo (e.g. `/tmp/vm-testing-baseline.txt`); verify the file holds five `.drv` paths
- [x] 1.2 Confirm neko and server-casper still fail only with the pre-existing `nextcloud-32.0.15` insecure error and note it in the change; verify by running the same eval for both and checking the error text

## 2. Central VM module (`modules/nix/vm-testing.nix`)

- [x] 2.1 Create `modules/nix/vm-testing.nix` (`{ inputs, ... }:` wrapper) defining `flake.modules.nixos.vm-testing` whose only content is `virtualisation.vmVariant = { config, lib, pkgs, ... }: { ... }`, append `inputs.self.modules.nixos.vm-testing` to the `makeNixos` module list in `modules/nix/helpers.nix`, and `git add` the new file (import-tree only sees tracked files); verify `nix eval .#nixosConfigurations.kaito.config.virtualisation.vmVariant.networking.hostName` returns `"kaito"`
- [x] 2.2 Add the isolation set with `lib.mkVMOverride`: `services.nebula.networks = { }`, `services.tailscale.enable = false`, `networking.wg-quick.interfaces = { }`, `security.acme.defaults.server = "https://127.0.0.1:1/acme-disabled-in-vm"`; verify with `nix eval` that kaito's vmVariant shows all four values while the real kaito config still has tailscale enabled and its Nebula network and `wgcasper` interface defined
- [x] 2.3 Add the guest-side oneshot that rejects outbound traffic to `10.0.2.2` (iptables, or nft when `networking.nftables.enable`), ordered before `network-online.target`; verify the unit exists in `config.virtualisation.vmVariant.systemd.services` and not in the real `config.systemd.services` for kaito and sakura
- [x] 2.4 Re-check `modules/` for services with outbound side effects not covered by the isolation set (grep for ddclient, restic, borg, syncthing, rclone, `OnCalendar` timers, webhooks, SMTP/mail relays, cloud or remote-push integrations); record the grep commands and findings in the change and add a VM-only override in the owning feature module for anything found; verify the recorded list has no uncovered item
- [x] 2.5 Add access settings: `services.getty.autologinUser = "casper"`, `security.sudo.wheelNeedsPassword = false`, `services.displayManager.autoLogin = { enable = true; user = "casper"; }` guarded by `config.services.xserver.displayManager.gdm.enable`, and `services.greetd.settings.initial_session = { user = "casper"; command = "Hyprland"; }` guarded by `config.services.greetd.enable`; verify with `nix eval` on kaito (getty), sakura (autoLogin) and technative-casper (greetd `initial_session`), and that the real configs keep `security.sudo.wheelNeedsPassword = true`
- [x] 2.6 Add resource and display defaults with `lib.mkDefault`: `memorySize = 4096`, `cores = 4`, `diskSize = 20480`, `graphics = config.services.xserver.enable || config.programs.hyprland.enable`, and for Hyprland hosts `qemu.options` with `-device virtio-vga-gl -display gtk,gl=on` plus a 1920×1080 resolution; verify with `nix eval` that kaito has `graphics = false`, sakura `true`, and technative-casper's `qemu.options` contains `virtio-vga-gl`

## 3. Feature- and host-specific overrides

- [x] 3.1 In `modules/services/system/rtcwake.nix`, add `virtualisation.vmVariant` that disables the `rtcwake-hibernate` timer with `lib.mkVMOverride`; verify with a lazy `nix eval` of `nixosConfigurations.neko.config.virtualisation.vmVariant.systemd.timers.rtcwake-hibernate.wantedBy` (or `.enable`) on neko, and if the nextcloud error is forced, with a temporary uncommitted `permittedInsecurePackages` workaround that is reverted afterwards
- [x] 3.2 In `modules/hosts/kaito/configuration.nix`, set `virtualisation.vmVariant.virtualisation.memorySize = 8192;`; verify `nix eval` gives `8192` for kaito and `4096` for sakura
- [x] 3.3 Check server-casper's `boot.kernelPackages`; if it is a Raspberry Pi kernel, add a VM-only `boot.kernelPackages = lib.mkVMOverride pkgs.linuxPackages` in its host file; verify by evaluating `virtualisation.vmVariant.boot.kernelPackages.kernel.name` (with the same temporary nextcloud workaround as 3.1 if needed)

## 4. Launchers (`perSystem.apps.vm-<host>`)

- [x] 4.1 Implement the launcher as a `writeShellApplication` wrapping `<host>.config.system.build.vm`: `NIX_DISK_IMAGE=${XDG_STATE_HOME:-$HOME/.local/state}/lkasper-vms/<host>.qcow2` (directory created), `--reset`, `--ssh-port N` (default 2222), repeatable `--forward HOST:GUEST`, `--headless`, `--help`, `QEMU_NET_OPTS` with every `hostfwd` bound to `127.0.0.1`, a warning when `/dev/kvm` is not writable, a warning below 10 GB free in the state directory, and the SSH command printed before start; verify the launcher builds (shellcheck runs as part of `writeShellApplication`) and `nix run .#vm-kaito -- --help` prints usage without starting QEMU
- [x] 4.2 Generate `apps.x86_64-linux` for every host from `builtins.attrNames self.nixosConfigurations` and `apps.aarch64-linux` only for aarch64 hosts; for server-casper on x86_64, use `extendModules` with `virtualisation.vmVariant.virtualisation.host.pkgs` set to x86_64 pkgs; verify `nix eval .#apps.x86_64-linux --apply builtins.attrNames` lists all seven `vm-*` apps, `nix eval .#apps.aarch64-linux --apply builtins.attrNames` lists only `vm-server-casper`, and `vm-kaito` evaluates while `vm-neko` fails on its own
- [x] 4.3 Add `*.qcow2` to `.gitignore`; verify `git check-ignore -v kaito.qcow2` matches the new rule

## 5. No-regression check and kaito VM tests (on the workstation, no real host touched)

- [x] 5.1 Re-evaluate the five toplevel derivation paths and diff them against the file from 1.1; verify they are byte-identical
- [x] 5.2 Boot `nix run .#vm-kaito -- --headless` and verify it reaches `multi-user.target` with agenix secrets failing to decrypt and `systemctl --failed` listing only secret-dependent units (e.g. AIOStreams) and ACME; if agenix aborts activation instead, add the VM-only fallback that skips the agenix activation snippet and re-run this check
- [x] 5.3 In the kaito VM, verify isolation: `ip -br link` shows no Nebula, Tailscale or WireGuard interface; `curl -m5 http://10.0.2.2:<any workstation port>` fails while `curl -sI https://nixos.org` succeeds; the ACME units fail against `127.0.0.1:1` with no request to Let's Encrypt in the journal; on the workstation `ss -ltn` shows the forwarded ports only on `127.0.0.1`
- [x] 5.4 Verify access in the kaito VM: the console logs in as casper without a password, `sudo -n true` succeeds, `ssh -p 2222 casper@127.0.0.1` works with the existing key, and `--forward 8123:8123` makes Home Assistant reachable at `http://127.0.0.1:8123`
- [x] 5.5 Verify persistence and isolation from the owner's files: a file created in the VM survives a restart, `--reset` removes it, the image lives at `~/.local/state/lkasper-vms/kaito.qcow2`, and `git status` plus a listing of the working directory show no new files outside the state directory
- [x] 5.6 Verify no secret leaks into the VM closure: diff `nix path-info -r` of the kaito VM against the real kaito toplevel and confirm the additions are only QEMU/VM tooling and no decrypted secret material

## 6. Desktop and cross-architecture VM tests

- [x] 6.1 Boot `nix run .#vm-sakura` and verify a window opens and GDM logs casper into GNOME automatically
- [x] 6.2 Boot one Hyprland host (`vm-personal-casper` or `vm-technative-casper`) and verify greetd starts Hyprland for casper under `virtio-vga-gl`; if Hyprland does not start, record it as a best-effort limitation and verify the console autologin still gives a shell
- [x] 6.3 Run `vm-kaito` and `vm-sakura` at the same time with `--ssh-port 2223` for one of them; verify both are reachable on their own port and do not see each other
- [x] 6.4 Try `nix run .#vm-server-casper -- --headless`; verify it boots to a login under emulation, or, while the nextcloud evaluation error is still unfixed, record that it is blocked and by what

## 7. Documentation and hand-off

- [x] 7.1 Add a "Testing a host in a VM" section to `README.md` (commands, options, state directory, cleanup with `rm ~/.local/state/lkasper-vms/*` and `nix-collect-garbage`, one heavy VM at a time, what does not work: secrets, hardware, mesh/VPN, ACME log noise); verify every option in the README matches the `--help` output
- [x] 7.2 Show the full diff to the owner and commit and push only after explicit approval; verify no real host was rebuilt or deployed as part of this change
