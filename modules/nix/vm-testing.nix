# Local, isolated, secret-free test VMs for every NixOS host:
#
#   nix run .#vm-<host> -- [--reset] [--ssh-port N] [--forward HOST:GUEST] [--headless]
#
# Everything below only writes into `virtualisation.vmVariant`, which the real
# system never reads, so the real hosts stay byte-identical.
{ inputs, lib, ... }:
let
  # QEMU user-mode NAT maps these gateway addresses to the workstation's own
  # loopback, so they are blocked inside the VM.
  workstationIPv4 = "10.0.2.2";
  workstationIPv6 = "fec0::2";
in
{
  flake.modules.nixos.vm-testing = { ... }: {
    virtualisation.vmVariant = { config, lib, pkgs, ... }:
      let
        hyprland = config.programs.hyprland.enable;
      in
      {
        # No outward identity of the real host. mkVMOverride (priority 10)
        # also beats mkForce in host modules.
        services.nebula.networks = lib.mkVMOverride { };
        services.tailscale.enable = lib.mkVMOverride false;
        networking.wg-quick.interfaces = lib.mkVMOverride { };
        # Certificate orders fail locally instead of reaching Let's Encrypt;
        # nginx keeps serving the preliminary self-signed certificate.
        security.acme.defaults.server = lib.mkVMOverride "https://127.0.0.1:1/acme-disabled-in-vm";

        # Keep processes and containers in the VM away from services on the
        # workstation. This is an accident guard, not a security boundary:
        # root in the VM can remove it. DHCP renewals to the gateway still pass.
        # Only new connections are blocked: forwarded ports (SSH, --forward)
        # arrive from the gateway address, so their replies must get through.
        systemd.services.vm-block-workstation = {
          description = "Test VM: block access to the workstation through the NAT gateway";
          wantedBy = [ "multi-user.target" ];
          before = [ "network-online.target" ];
          after = [ "firewall.service" "nftables.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ config.networking.firewall.package ];
          script =
            if config.networking.nftables.enable then ''
              nft -f - <<'EOF'
              table inet vm-isolation
              delete table inet vm-isolation
              table inet vm-isolation {
                chain output {
                  type filter hook output priority filter; policy accept;
                  ct state established,related return
                  ip daddr ${workstationIPv4} udp dport 67 return
                  ip daddr ${workstationIPv4} reject
                  ip6 daddr ${workstationIPv6} reject
                }
                chain prerouting {
                  type filter hook prerouting priority mangle; policy accept;
                  ct state new ip daddr ${workstationIPv4} drop
                  ct state new ip6 daddr ${workstationIPv6} drop
                }
              }
              EOF
            '' else ''
              block() {
                local cmd=$1 addr=$2
                $cmd -w -N vm-isolation 2>/dev/null || $cmd -w -F vm-isolation
                $cmd -w -A vm-isolation -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
                if [ "$cmd" = iptables ]; then
                  $cmd -w -A vm-isolation -p udp --dport 67 -j RETURN
                fi
                $cmd -w -A vm-isolation -j REJECT
                $cmd -w -C OUTPUT -d "$addr" -j vm-isolation 2>/dev/null \
                  || $cmd -w -I OUTPUT -d "$addr" -j vm-isolation
                # Forwarded traffic, e.g. from Docker containers in the VM.
                # The mangle table runs after conntrack, unlike raw, so
                # container replies to forwarded ports still pass.
                $cmd -w -t mangle -C PREROUTING -d "$addr" -m conntrack --ctstate NEW -j DROP 2>/dev/null \
                  || $cmd -w -t mangle -I PREROUTING -d "$addr" -m conntrack --ctstate NEW -j DROP
              }
              block iptables ${workstationIPv4}
              if [ -e /proc/net/if_inet6 ]; then
                block ip6tables ${workstationIPv6}
              fi
            '';
        };

        # Access inside the VM only; no password is stored anywhere.
        services.getty.autologinUser = lib.mkVMOverride "casper";
        security.sudo.wheelNeedsPassword = lib.mkVMOverride false;
        services.displayManager.autoLogin = lib.mkIf config.services.displayManager.gdm.enable {
          enable = true;
          user = "casper";
        };
        services.greetd.settings.initial_session = lib.mkIf config.services.greetd.enable {
          user = "casper";
          command = "Hyprland";
        };

        # agenix creates the parent folders of secrets kept in a home folder
        # (e.g. ~/.config/jiratui) as root. On a fresh VM disk that happens
        # before the user ever logged in, so ~/.config ends up owned by root
        # and the login shell cannot write its config. Hand it back.
        system.activationScripts.vmHomeConfigOwner = {
          deps = [ "users" ] ++ lib.optional (config ? age && config.age.secrets != { }) "agenix";
          text = lib.concatMapStrings (user:
            let dir = lib.escapeShellArg "${user.home}/.config"; in ''
              if [ -d ${dir} ] && [ "$(stat -c %u ${dir})" = 0 ]; then
                chown ${user.name}:${user.group} ${dir}
              fi
            '') (lib.filter (user: user.isNormalUser && user.createHome)
              (lib.attrValues config.users.users));
        };

        # Resources and display; a host can override these with a plain
        # assignment in its own host file.
        virtualisation = {
          memorySize = lib.mkDefault 4096;
          cores = lib.mkDefault 4;
          diskSize = lib.mkDefault 20480;
          graphics = lib.mkDefault (config.services.xserver.enable || hyprland);
          # Hyprland needs GBM/EGL, which plain VGA does not offer.
          resolution = lib.mkIf hyprland (lib.mkDefault { x = 1920; y = 1080; });
          qemu.options = lib.mkIf hyprland [
            "-vga none"
            "-device virtio-vga-gl,xres=1920,yres=1080"
            "-display gtk,gl=on"
          ];
        };
      };
  };

  perSystem = { pkgs, system, ... }:
    let
      hosts = inputs.self.nixosConfigurations;
      hostNames = builtins.attrNames hosts;
      hostSystem = name: hosts.${name}.config.nixpkgs.hostPlatform.system;

      # x86_64 can emulate the aarch64 hosts; other systems only run their own.
      # On x86_64 the list needs no host evaluation, so a host that fails to
      # evaluate only breaks its own launcher.
      launchable =
        if system == "x86_64-linux" then hostNames
        else lib.filter (name: hostSystem name == system) hostNames;

      mkLauncher = name:
        let
          native = hostSystem name == system;
          evaluated =
            if native then hosts.${name}
            else hosts.${name}.extendModules {
              # Run the foreign-architecture VM with this system's QEMU (TCG).
              modules = [{ virtualisation.vmVariant.virtualisation.host.pkgs = pkgs; }];
            };
          vm = evaluated.config.virtualisation.vmVariant;
          graphical = vm.virtualisation.graphics;
          headlessOpts =
            if !graphical then ""
            # virtio-vga-gl needs a GL context even without a window.
            else if vm.programs.hyprland.enable then "-nographic -display egl-headless"
            else "-nographic";
        in
        pkgs.writeShellApplication {
          name = "vm-${name}";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            host=${lib.escapeShellArg name}
            run_vm=${lib.escapeShellArg "${vm.system.build.vm}/bin/run-${vm.system.name}-vm"}
            headless_opts=${lib.escapeShellArg headlessOpts}
            state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/lkasper-vms"
            image="$state_dir/$host.qcow2"
            ssh_port=2222
            reset=0
            headless=0
            forwards=()

            usage() {
              cat <<EOF
            Usage: vm-$host [OPTIONS] [-- QEMU-ARGS...]

            Boot the NixOS host '$host' as an isolated, secret-free test VM.

            Options:
              --reset               Delete this host's disk image first and boot fresh
              --ssh-port N          Workstation port for SSH into the VM (default: 2222)
              --forward HOST:GUEST  Forward TCP port HOST on the workstation to port
                                    GUEST in the VM (repeatable)
              --headless            No VM window; use the console in this terminal
              -h, --help            Show this help and exit

            Disk image: $image
            Forwarded ports listen on 127.0.0.1 only. The VM gets no secrets.
            EOF
            }

            die() {
              echo "vm-$host: $*" >&2
              exit 2
            }

            warn() {
              echo "vm-$host: warning: $*" >&2
            }

            check_port() {
              case "$1" in
                "" | *[!0-9]*) die "invalid port '$1'" ;;
              esac
              if [ "$1" -lt 1 ] || [ "$1" -gt 65535 ]; then
                die "port out of range: $1"
              fi
            }

            while [ "$#" -gt 0 ]; do
              case "$1" in
                --reset) reset=1 ;;
                --ssh-port)
                  [ "$#" -ge 2 ] || die "--ssh-port needs a port number"
                  ssh_port=$2
                  shift
                  ;;
                --ssh-port=*) ssh_port=''${1#*=} ;;
                --forward)
                  [ "$#" -ge 2 ] || die "--forward needs HOST:GUEST"
                  forwards+=("$2")
                  shift
                  ;;
                --forward=*) forwards+=("''${1#*=}") ;;
                --headless) headless=1 ;;
                -h | --help)
                  usage
                  exit 0
                  ;;
                --)
                  shift
                  break
                  ;;
                *)
                  usage >&2
                  die "unknown option '$1'"
                  ;;
              esac
              shift
            done

            # Every forward binds to 127.0.0.1; QEMU's default would listen on
            # all workstation interfaces.
            check_port "$ssh_port"
            net_opts="hostfwd=tcp:127.0.0.1:$ssh_port-:22"
            for fwd in "''${forwards[@]}"; do
              case "$fwd" in
                *:*) ;;
                *) die "--forward expects HOST:GUEST, got '$fwd'" ;;
              esac
              check_port "''${fwd%%:*}"
              check_port "''${fwd#*:}"
              net_opts="$net_opts,hostfwd=tcp:127.0.0.1:''${fwd%%:*}-:''${fwd#*:}"
            done

            mkdir -p "$state_dir"
            if [ "$reset" -eq 1 ] && [ -e "$image" ]; then
              rm -f "$image"
              echo "vm-$host: removed $image"
            fi

            ${if native then ''
              if [ ! -e /dev/kvm ]; then
                warn "/dev/kvm is missing; QEMU falls back to software emulation (very slow)"
              elif [ ! -w /dev/kvm ]; then
                warn "/dev/kvm is not writable for $(id -un); QEMU falls back to software emulation (very slow)"
              fi
            '' else ''
              echo "vm-$host: ${hostSystem name} host, emulated without KVM; expect a slow boot"
            ''}
            avail_gb=$(df --output=avail -BG "$state_dir" | tail -n 1 | tr -dc '0-9')
            if [ "''${avail_gb:-0}" -lt 10 ]; then
              warn "only ''${avail_gb:-0} GB free in $state_dir; the disk image can grow to ${toString (vm.virtualisation.diskSize / 1024)} GB"
            fi

            # Share no workstation folder beyond the run's own fresh temp dir.
            unset SHARED_DIR USE_TMPDIR
            export NIX_DISK_IMAGE="$image"
            export QEMU_NET_OPTS="$net_opts"
            if [ "$headless" -eq 1 ] && [ -n "$headless_opts" ]; then
              export QEMU_OPTS="''${QEMU_OPTS:+$QEMU_OPTS }$headless_opts"
            fi

            echo "vm-$host: disk image $image"
            echo "vm-$host: ssh -p $ssh_port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null casper@127.0.0.1"
            for fwd in "''${forwards[@]}"; do
              echo "vm-$host: 127.0.0.1:''${fwd%%:*} -> VM port ''${fwd#*:}"
            done
            echo "vm-$host: stop with 'sudo poweroff' in the VM"

            exec "$run_vm" "$@"
          '';
        };
    in
    {
      apps = lib.listToAttrs (map
        (name: lib.nameValuePair "vm-${name}" {
          type = "app";
          program = lib.getExe (mkLauncher name);
          meta.description = "Boot ${name} as an isolated, secret-free test VM";
        })
        launchable);
    };
}
