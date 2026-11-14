# Design

## Context

- Every `nixosConfiguration` already ships NixOS's own VM support (`nixos/modules/virtualisation/build-vm.nix` with `qemu-vm.nix`):
  - `config.system.build.vm` is a `run-<host>-vm` script.
  - `virtualisation.vmVariant` is a separate evaluation, made with `extendModules`, that only that script uses.
- A baseline eval on 2026-11-12, run on technative-casper:
  - `system.build.vm` evaluates without changes for kaito, sakura, technative-casper, gaming-casper and personal-casper.
  - neko and server-casper fail to evaluate even for their real toplevel: `nextcloud-32.0.15` is marked insecure. That is pre-existing and out of scope.
- What `qemu-vm.nix` already does, as confirmed in the pinned nixpkgs source:
  - replaces `fileSystems` and empties `swapDevices` and `boot.initrd.luks.devices` (all `mkVMOverride`), so LUKS hosts boot without disks
  - forces `videoDrivers = [ "modesetting" ]`
  - mounts the workstation's `/nix/store` read-only at `/nix/.ro-store`, with a writable overlay
  - shares only fresh per-run temp directories (`/tmp/xchg`, `/tmp/shared`)
  - uses QEMU user-mode networking
- What it does not do, and this design adds:
  - It puts the disk image at `./<host>.qcow2`, relative to the working directory.
  - Defaults are 1024 MiB RAM, 1 core and graphics on.
- `casper` has no password anywhere in the repo, so a plain VM cannot be logged into.
- Secrets:
  - agenix decrypts at activation with the host SSH key.
  - Nebula certificates and keys, the WireGuard keys and the AIOStreams environment are all agenix secrets.
- ACME in this nixpkgs always generates a preliminary self-signed certificate (minica) before ordering, so nginx can start without a real certificate.
- Desktop session start differs per host:
  - sakura: GDM, GNOME
  - the Hyprland hosts: greetd with tuigreet, from the omarchy input
  - kaito, neko and server-casper: no desktop
- Workstation (technative-casper): 12 threads, 30 GiB RAM (about 18 GiB free), `/dev/kvm` usable by the user, aarch64 binfmt enabled. The root filesystem is 94% full (54 GB free).

## Goals / Non-Goals

**Goals:**
- One command per host to boot a faithful, isolated copy of that host's configuration (see `specs/host-vm-testing/spec.md`).
- Zero effect on real systems, provable by unchanged toplevel derivation paths.
- Generic safety overrides in one auditable place.

**Non-Goals:**
- Testing hardware: GPU, USB and zigbee sticks, fingerprint reader, Wake-on-LAN, bluetooth, Framework firmware.
- Testing the bootloader, LUKS or disk layout. `vmVariantWithBootLoader` stays unused.
- Making secret-dependent services work in the VM, whether with real or dummy secrets.
- Networking VMs to each other, for example a fake Nebula mesh between VM copies.
- Automated `nixosTest` checks or CI.
- The standalone home-manager configurations (nixhost, basic-home).
- Fixing the neko and server-casper nextcloud evaluation error.

## Decisions

### 1. Build on `virtualisation.vmVariant`, with no new tooling
The VM is the host's own NixOS configuration, extended through `virtualisation.vmVariant`.
- It needs no new flake input.
- It reuses the exact host modules.
- It boots from the shared store, so there is no image to build.
- It matches `nixos-rebuild build-vm`.
- **Alternatives:**
  - microvm.nix: an extra input, and per-VM config that drifts from the real host.
  - nixos-generators or libvirt images: a slow image build per change, and imperative import.
  - nspawn or `nixos-container`: shares the workstation kernel and network stack, so it cannot exercise boot, firewall or kernel modules, and it isolates less.

### 2. One central module, added to every host through `makeNixos`
`modules/nix/vm-testing.nix` is a flake-parts module wrapped in `{ inputs, ... }:`. It defines:
- `flake.modules.nixos.vm-testing`, whose only content is `virtualisation.vmVariant = { config, lib, pkgs, ... }: { ... }`
- the per-host launchers (Decision 6)

`modules/nix/helpers.nix` appends `inputs.self.modules.nixos.vm-testing` to the `makeNixos` module list. That way every current and future host gets a VM without edits to the seven host files.
- **Why this is acceptable in a dendritic repo:** the module only writes into `vmVariant`, which the real toplevel never reads, so including it implicitly cannot change a real system. Tasks 1.1 and 5.1 verify this with derivation paths.
- **Alternative:** an explicit `vm-testing` line in each host's imports. It is more explicit, but it means seven edits and is easy to forget for new hosts.
- **Feature-specific overrides live in the feature module.** Anything that names a unit that only exists when a feature is imported goes into that feature's own `virtualisation.vmVariant`. Example: `systemd.timers.rtcwake-hibernate` goes in `rtcwake.nix`. Setting it centrally would create stray unit definitions on hosts without the feature.

### 3. Overrides use `lib.mkVMOverride`
`mkVMOverride` is priority 10, the same mechanism `qemu-vm.nix` uses. It beats both `mkForce` (50) and plain definitions, so a host module cannot accidentally re-enable mesh or VPN inside the VM. Resource and display defaults use `lib.mkDefault` instead, so a host can override them with a plain assignment.

### 4. Isolation set (central)
- **Mesh and VPN:**
  - `services.nebula.networks = mkVMOverride { }`
  - `services.tailscale.enable = mkVMOverride false`
  - `networking.wg-quick.interfaces = mkVMOverride { }`
  - These options exist in every NixOS evaluation, so it is safe to set them on all hosts.
- **ACME:** `security.acme.defaults.server = mkVMOverride "https://127.0.0.1:1/acme-disabled-in-vm"`. Ordering fails locally without any traffic to Let's Encrypt, and nginx keeps serving the preliminary self-signed certificate.
  - **Alternative:** Let's Encrypt staging. Rejected, because it still sends real HTTP-01 challenges for domains that resolve to the real hosts.
- **Workstation access:** inside the VM, a small oneshot runs before `network-online.target`. It rejects new outbound connections to the slirp gateway `10.0.2.2`, which slirp maps to the workstation's loopback. DNS goes to `10.0.2.3` and still works.
  - Only connections the VM starts are blocked. Forwarded ports (SSH, `--forward`) reach the guest *from* `10.0.2.2`, so replies in conntrack state `ESTABLISHED`/`RELATED` pass. The rule for routed traffic, e.g. from containers, sits in the mangle table, which runs after conntrack, so container replies to forwarded ports pass too.
  - It is built as a dedicated unit with `iptables`, or `nft` when `networking.nftables.enable`, rather than through `networking.firewall.extraCommands`, so it works whichever firewall backend the host uses.
  - It is an accident guard, not a security boundary: root in the VM can remove it.
  - **Alternative:** QEMU `restrict=on`. Rejected, because it also cuts internet access, which containers need to pull images.
- **No forwards in the build:** `virtualisation.forwardPorts` stays empty. All forwards are set per run by the launcher (Decision 6), so ports never require a rebuild.

### 5. No secrets; access without passwords
- **Secrets:**
  - The VM generates its own fresh SSH host key on first boot, inside its qcow2. That key is not an agenix recipient, so every secret fails to decrypt.
  - NixOS runs each activation snippet and continues after a failing one, so boot proceeds and the dependent services fail visibly.
  - No identity is ever shared or baked in.
  - **Alternatives:**
    - Adding a VM recipient to `secrets/secrets.nix`. Rejected: that puts real secrets in the VM.
    - Dummy secrets encrypted to a public test key, substituted per `age.secrets.<name>.file`. Deferred; see Open Questions.
- **Access:**
  - `services.getty.autologinUser = "casper"` and `security.sudo.wheelNeedsPassword = false`.
  - Graphical autologin where a display manager exists: `services.displayManager.autoLogin = { enable = true; user = "casper"; }` for GDM, and `services.greetd.settings.initial_session = { user = "casper"; command = "Hyprland"; }` guarded by `lib.mkIf config.services.greetd.enable`.
  - SSH keeps working with casper's existing authorized key.
  - agenix creates the parent folders of secrets kept in a home folder (e.g. `~/.config/jiratui`) as root. On a fresh VM disk that leaves `~/.config` owned by root and the login shell can't write its config. A VM-only activation snippet, `vmHomeConfigOwner`, runs after `agenix` and returns a root-owned `~/.config` to its user. Real hosts already have their own `~/.config` and don't get the snippet.
  - **Alternative:** `initialPassword = "..."`. Rejected, because it is a password literal in a public repo.

### 6. Launchers as `perSystem.apps.vm-<host>`
Each launcher is a `writeShellApplication` wrapper around `<host>.config.system.build.vm`. It:
- sets `NIX_DISK_IMAGE=${XDG_STATE_HOME:-$HOME/.local/state}/lkasper-vms/<host>.qcow2` and creates the directory
- `--reset`: deletes that image first
- `--ssh-port N`: default 2222
- `--forward HOST:GUEST`: repeatable
- `--headless`: adds `-nographic` through `QEMU_OPTS`
- builds `QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:<ssh>-:22,hostfwd=tcp:127.0.0.1:<h>-:<g>,…"`. The explicit `127.0.0.1` matters: QEMU's default `hostfwd=tcp::P-:22` listens on every workstation interface.
- warns if `/dev/kvm` is not writable, in which case QEMU falls back to TCG
- warns if less than 10 GB is free at the state directory
- prints the SSH command before starting

Which launchers exist:
- `apps.x86_64-linux` contains every host. The attribute names come from `builtins.attrNames self.nixosConfigurations`, which keeps evaluation lazy, so a broken host only fails its own launcher.
- `apps.aarch64-linux` contains only the aarch64 hosts, filtered on `nixpkgs.hostPlatform.system`.

**Alternative:** one `vm` app that takes the host name and calls `nix build` at runtime. It is less discoverable, nests Nix calls, and makes `nix flake show` unhelpful.

### 7. Resources and display defaults
- **Resources:** `memorySize = mkDefault 4096`, `cores = mkDefault 4` and `diskSize = mkDefault 20480`. The qcow2 is sparse.
- **kaito:** sets `virtualisation.vmVariant.virtualisation.memorySize = 8192;` in its host file, because Ollama, Home Assistant, Minecraft and Docker are too much for 4 GiB.
- **Display:** `virtualisation.graphics = mkDefault (config.services.xserver.enable || config.programs.hyprland.enable)`. Every desktop host imports the `xserver` module; kaito, neko and server-casper don't, so they come out headless.
- **Hyprland hosts:** they also get `-device virtio-vga-gl -display gtk,gl=on` and a 1920×1080 resolution, because Hyprland needs GBM/EGL.

### 8. server-casper on x86_64
For the x86_64 launcher, server-casper's configuration is extended (`extendModules`) with `virtualisation.vmVariant.virtualisation.host.pkgs = <x86_64 pkgs>`. `qemu-vm.nix` then runs `qemu-system-aarch64` under TCG on the workstation. Its closure is aarch64: most comes from the binary cache, and the rest is built through binfmt.

### 9. Repository hygiene
- `.gitignore` gets `*.qcow2`, for anyone running `nixos-rebuild build-vm` directly in the repo.
- The README gets a "Testing a host in a VM" section.

## Risks / Trade-offs

- **[Workstation disk is 94% full]** → qcow2 images are sparse, `--reset` deletes them, the launcher warns below 10 GB, and the README documents removing `~/.local/state/lkasper-vms/*` and `nix-collect-garbage`.
- **[RAM: kaito VM at 8 GiB plus a desktop VM on a workstation with about 18 GiB free]** → defaults are modest, and the README advises running one heavy VM at a time.
- **[agenix might abort activation instead of continuing]** → task 5.2 verifies a kaito VM boots to multi-user with failed secrets. If agenix does abort, the fallback is a VM-only override that skips the agenix activation snippet.
- **[A service with unauthenticated outbound side effects that the isolation set does not cover]** → a repo grep found no DDNS, restic, borg or sync jobs. Task 2.4 re-checks before merge, and the requirement in the spec makes any such service a defect.
- **[Hyprland may not start under virtio-gpu]** → desktop VMs are best-effort. The console autologin still gives a shell, and the GNOME host (sakura) is the reference desktop test.
- **[server-casper may use a Raspberry Pi kernel that cannot boot on QEMU `virt`]** → if so, add a VM-only `boot.kernelPackages = mkVMOverride pkgs.linuxPackages` in server-casper's host file. This is blocked anyway until its nextcloud error is fixed.
- **[The read-only workstation `/nix/store` is visible to the VM]** → it holds only world-readable store paths, and agenix files there are encrypted. For stricter isolation, `virtualisation.useNixStoreImage` can be enabled per host, at the cost of slower builds and more disk.
- **[The guest-to-workstation block is removable by VM root]** → accepted. It guards against accidental access from configs, not against a hostile guest.
- **[Extra evaluation time: `nix flake show` and `check` now evaluate a VM per host, about 15–20 s each]** → accepted. `flake check` already fails on neko today, so this is no regression.
- **[ACME order units keep failing on their timer in the VM]** → log noise only, documented.
- **[First boot of kaito's VM pulls all Docker images and downloads models]** → time and bandwidth on the first run only. The data stays in the qcow2 until `--reset`.

## Migration Plan

1. Record the toplevel derivation paths of the five hosts that evaluate.
2. Add the module, the `makeNixos` line, the rtcwake override and kaito's memory override.
3. Re-evaluate and confirm the derivation paths are identical.
4. Boot `vm-kaito` first, since it is the main target for add-holyarrs, and walk through the isolation scenarios. Then boot sakura (GNOME), then one Hyprland host.
5. Write the README section, show the diff, and commit and push only after the owner approves.

Nothing is deployed to any real host. Rollback means removing the module and the `makeNixos` line; real systems are unaffected either way.

## Open Questions

- Should a later change add dummy test secrets (a public VM-only age key with placeholder `.age` files) so secret-consuming services can be smoke-tested? That can be added on top without changing this design.
- Should `nixosTest`-based automated checks reuse these overrides later?
