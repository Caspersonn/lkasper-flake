# Spec Delta

## Purpose

Lets the owner boot any NixOS host of this flake as a local, isolated, secret-free QEMU test VM, so configuration changes can be tried before they are deployed to the real machine, without touching the real host, the owner's own files or the outside world.

The capability is delivered as a NixOS module plus per-host flake apps, both living in `modules/nix/`. It is not a home-manager config and not an overlay.

## ADDED Requirements

### Requirement: Per-host VM launcher
The flake SHALL expose, for every NixOS host under `modules/hosts/`, a runnable app named `vm-<host>` that builds and boots that host's own NixOS configuration as a QEMU VM. Running it SHALL need nothing beyond `nix run` as the normal workstation user: no root, no extra tooling installed by hand.

#### Scenario: Start a host VM
- **WHEN** the owner runs `nix run .#vm-kaito` on an x86_64 workstation
- **THEN** a VM boots kaito's configuration, with kaito's hostname, services, users and home-manager config, plus only the VM overrides defined by this capability

#### Scenario: No root needed
- **WHEN** the owner runs a launcher as an unprivileged user who can access `/dev/kvm`
- **THEN** the VM starts with KVM acceleration and no sudo prompt

#### Scenario: KVM not available
- **WHEN** `/dev/kvm` is missing or not accessible
- **THEN** the launcher prints a clear warning and either falls back to software emulation or stops with an explanation; it SHALL NOT fail silently

#### Scenario: Broken host does not block others
- **WHEN** one host's configuration fails to evaluate (for example neko because of an insecure package)
- **THEN** `nix run .#vm-<other-host>` still works for every host that evaluates

### Requirement: Real host systems are unaffected
Adding VM support SHALL NOT change any host's real system. For every host, the derivation of the real system (the one `nixos-rebuild switch` deploys) SHALL be identical with and without this capability.

#### Scenario: Toplevel derivations unchanged
- **WHEN** the system derivation path of each host is evaluated before and after this change
- **THEN** the paths are identical for every host that evaluates

#### Scenario: VM-only settings stay in the VM
- **WHEN** the real host is deployed
- **THEN** it has no console autologin, no passwordless sudo and no disabled mesh/VPN services coming from this capability

### Requirement: Isolation from the owner's files
A VM SHALL keep all its writable state in a per-host disk image outside the repository, under `~/.local/state/lkasper-vms/<host>.qcow2`. The image SHALL persist between runs until it is reset on purpose. No home directory, repository or other workstation folder SHALL be shared into the VM writable. The only workstation path visible in the VM is the Nix store, read-only.

#### Scenario: State persists between runs
- **WHEN** the owner creates a file in the VM, shuts it down and starts the same launcher again
- **THEN** the file is still there

#### Scenario: Reset
- **WHEN** the owner runs `nix run .#vm-<host> -- --reset`
- **THEN** that host's disk image is deleted and the VM boots from a fresh state, while other hosts' images are untouched

#### Scenario: Nothing written to the workstation
- **WHEN** a VM runs, including home-manager activation and service start-up inside it
- **THEN** nothing on the workstation changes except that host's disk image and temporary files of the run; the repository working tree stays unchanged

### Requirement: Network isolation
A VM SHALL use NAT networking: it can reach the internet but SHALL NOT be reachable from the LAN or any other machine. Every port forwarded from the workstation into the VM SHALL bind to `127.0.0.1` only. SSH to the VM SHALL be forwarded to `127.0.0.1:2222` by default, and the port SHALL be changeable per run so several VMs can run at once. Extra service ports SHALL be forwardable per run without rebuilding. By default the VM SHALL NOT be able to connect to services listening on the workstation through the NAT gateway. DNS resolution through QEMU's built-in resolver keeps working.

#### Scenario: Workstation services not reachable from the VM
- **WHEN** a process in the VM connects to the NAT gateway address (`10.0.2.2`) on a port where a workstation service listens, for example on `127.0.0.1`
- **THEN** the connection is refused or dropped, while internet access and DNS from the VM keep working

#### Scenario: SSH into the VM
- **WHEN** a VM is running with default settings
- **THEN** `ssh -p 2222 casper@127.0.0.1` reaches the VM using casper's existing authorized key

#### Scenario: Not reachable from the LAN
- **WHEN** another device on the LAN connects to the workstation's LAN address on a forwarded port
- **THEN** the connection does not reach the VM

#### Scenario: Two VMs at once
- **WHEN** the owner starts a second VM with a different SSH port
- **THEN** both VMs run and are each reachable on their own port

#### Scenario: Reach a web UI in the VM
- **WHEN** the owner starts a VM with an extra forward for a service port (for example kaito's Home Assistant on 8123)
- **THEN** the service answers on `127.0.0.1:<chosen port>` on the workstation

### Requirement: No real secrets in the VM
A VM SHALL never receive key material that can decrypt the repository's agenix secrets. Host SSH keys, the owner's age or SSH identities and decrypted secrets SHALL NOT be copied, shared or baked into the VM or its disk image. Services that depend on an agenix secret SHALL fail visibly in the VM instead of running with real credentials. That failure is expected behaviour.

#### Scenario: Secrets stay encrypted
- **WHEN** a VM boots
- **THEN** none of the host's agenix secrets are decrypted inside it, and secret target paths are missing or empty

#### Scenario: Secret-dependent service fails visibly
- **WHEN** a service needs an agenix secret (for example AIOStreams' environment file on kaito)
- **THEN** that service shows as failed in `systemctl --failed` in the VM, and the VM otherwise keeps booting

#### Scenario: No secret leaks through the store
- **WHEN** the VM's closure is built
- **THEN** it contains no decrypted secret and no private key from the workstation

### Requirement: No outward identity of the real host
A VM SHALL NOT present itself to other systems as the real host or interfere with the real infrastructure. In the VM:
- Nebula mesh membership, Tailscale and WireGuard interfaces SHALL NOT start.
- No certificate SHALL be requested from a real ACME certificate authority.
- Host power-management timers such as rtcwake hibernation SHALL be inactive.

#### Scenario: Mesh and VPN stay down
- **WHEN** a VM of a mesh/VPN member boots (for example kaito, the Nebula lighthouse and WireGuard server)
- **THEN** no Nebula, Tailscale or WireGuard interface or service is active in the VM, and the real mesh and VPN keep working

#### Scenario: No ACME requests
- **WHEN** a VM of a host with ACME-enabled virtual hosts boots
- **THEN** no request is sent to Let's Encrypt or another public CA, and the web server can still start (for example with a self-signed certificate)

#### Scenario: No hibernation timer
- **WHEN** a VM of neko boots
- **THEN** the rtcwake hibernation timer is not active

### Requirement: Usable access inside the VM
In the VM only, the console SHALL log in automatically as `casper`, and `casper` SHALL be able to use sudo without a password. No password SHALL be stored in the repository for this.

#### Scenario: Console login
- **WHEN** a VM finishes booting
- **THEN** its console shows a shell (or the host's graphical session start) logged in as `casper`, with no password prompt

#### Scenario: Administration in the VM
- **WHEN** the owner runs `sudo systemctl status <service>` in the VM
- **THEN** the command runs without a password prompt

### Requirement: Resources and display
A VM SHALL default to 4 GiB RAM, 4 virtual cores and a 20 GiB sparse disk. A host SHALL be able to override these in its own host module. Hosts with a graphical desktop SHALL open a VM window. Hosts without a desktop SHALL run headless, with the console in the launching terminal.

#### Scenario: Default resources
- **WHEN** a host defines no overrides
- **THEN** its VM has 4 GiB RAM, 4 cores and a disk of up to 20 GiB that grows only as data is written

#### Scenario: Per-host override
- **WHEN** a host module sets a larger memory size for its VM (for example 8 GiB for kaito)
- **THEN** that host's VM uses it, and other hosts keep the defaults

#### Scenario: Server runs headless
- **WHEN** the owner starts a VM of a host without a desktop (kaito, neko, server-casper)
- **THEN** no graphical window opens and the VM console is attached to the terminal

#### Scenario: Desktop opens a window
- **WHEN** the owner starts a VM of a desktop host (sakura, technative-casper, gaming-casper, personal-casper)
- **THEN** a VM window opens showing the host's login or session screen

### Requirement: Cross-architecture host
The aarch64 host server-casper SHALL also be launchable from an x86_64 workstation, using software emulation. Speed is not guaranteed.

#### Scenario: Emulated aarch64 VM
- **WHEN** the owner runs `nix run .#vm-server-casper` on an x86_64 workstation that has aarch64 binfmt support, once server-casper evaluates again
- **THEN** an aarch64 VM of server-casper boots under emulation

### Requirement: Documented usage
The repository README SHALL explain:
- how to start, reach, reset and remove a host VM
- which ports and paths it uses
- that secret-dependent and hardware-dependent services are expected to fail in the VM

#### Scenario: Owner looks up how to test a host
- **WHEN** the owner opens README.md
- **THEN** it contains a section that lists the `vm-<host>` launchers, the `--reset` and port options, the state location and the known limitations
