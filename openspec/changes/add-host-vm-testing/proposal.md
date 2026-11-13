# Proposal

## Why

Host changes, such as the planned HolyArrs setup on kaito, can only be tested today by deploying them to the real machine. A broken activation then hits live services and data, and kaito has already been unstable. NixOS can build a QEMU VM from any `nixosConfiguration`, but used as-is that VM is not usable or safe enough:
- it writes its disk image into the current directory (the repo)
- it gets 1 GiB RAM and 1 core
- `casper` has no password, so nobody can log in or use sudo
- nothing explicitly stops it from presenting itself to the outside world as the real host (Nebula, WireGuard, Tailscale, ACME)

## What Changes

- Every NixOS host gets a local test VM, started with `nix run .#vm-<host>`. The VM boots the host's real configuration with a small set of VM-only overrides.
- The VM is isolated from the user's own machine:
  - it keeps its own persistent disk image under `~/.local/state/lkasper-vms/<host>.qcow2`
  - only the Nix store is shared, read-only; no home directory or other host folder
  - it uses QEMU user-mode NAT, so it is not visible on the LAN
  - forwarded ports bind to `127.0.0.1` only (SSH on 2222 by default)
- The VM never receives real secrets. Host SSH keys and age identities are never passed in, so agenix secrets stay encrypted. Services that need a secret fail inside the VM, and that is documented as expected behaviour.
- The VM does not act as the real host on the outside. Nebula, Tailscale and WireGuard are disabled, ACME never contacts Let's Encrypt, and host-specific power timers (rtcwake) are off.
- Access inside the VM: automatic console login as `casper` and sudo without a password, in the VM only. SSH still works with the existing authorized key.
- Defaults are usable: 4 GiB RAM, 4 cores and a 20 GiB sparse disk. A host can override these in its own host file, for example 8 GiB for kaito.
- `nix run .#vm-<host> -- --reset` throws the disk image away and starts fresh.
- Real hosts do not change. All overrides live in `virtualisation.vmVariant`, and every host's real system derivation stays byte-identical.
- The README gets a short section on how to start, reach and reset a VM.

## Capabilities

### New Capabilities
- `host-vm-testing`: building and running an isolated, secret-free QEMU test VM for any NixOS host in this flake, without side effects on the real host, the user's files or the outside world.

### Modified Capabilities
<!-- None. The existing `nixos-configurations` spec is stale (it still describes parts/nixos.nix and makeNixosConf); this change adds no requirements to it. -->

## Impact

- **New module**: `modules/nix/vm-testing.nix`, a flake-parts module that provides:
  - `flake.modules.nixos.vm-testing`, holding the VM-only overrides
  - `perSystem.apps.vm-<host>`, one launcher per host
- **Changed**:
  - `modules/nix/helpers.nix`: `makeNixos` adds `vm-testing` to every host, so the seven host files need no extra import lines.
  - `modules/services/system/rtcwake.nix`: switches its timer off inside the VM.
  - Optional per-host tuning in `modules/hosts/<host>/configuration.nix`.
  - `.gitignore` gets `*.qcow2`, and the README gets the new section.
- **Hosts**: all seven NixOS hosts: kaito, sakura, technative-casper, gaming-casper, personal-casper, neko and server-casper. The project context lists only four, which is outdated.
  - The x86_64 hosts run under KVM.
  - server-casper (aarch64) runs emulated on x86_64. That is slow and best-effort, and relies on the aarch64 binfmt that technative-casper already has.
- **Pre-existing blocker**: neko and server-casper currently fail to evaluate at all, VM or not, because `nextcloud-32.0.15` is marked insecure. Their VMs only work once that is fixed. The fix is a separate change.
- **Home-manager**:
  - Home-manager runs as part of each NixOS config, so it is included in the VM and activates only inside it.
  - The standalone home-manager configs (nixhost, basic-home) are not covered.
  - The home-manager dendritic migration is not affected.
- **Dependencies**: none new; QEMU comes from nixpkgs.
- **Disk space**: technative-casper's root filesystem is 94% full (about 54 GB free). VM closures and disk images take extra space.
- **Follow-ups**: `add-holyarrs` needs no agenix secrets, so it can be tested in `vm-kaito` before anything is deployed to the real kaito.
