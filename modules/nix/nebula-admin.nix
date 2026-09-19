{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
    let
      nebula-admin = pkgs.writeShellApplication {
        name = "nebula-admin";

        runtimeInputs = [
          pkgs.nebula
          pkgs.jq
          pkgs.git
          pkgs.coreutils
          pkgs.nix
          inputs.agenix.packages.${system}.default
        ];

        text = ''
          CA_NAME="''${NEBULA_CA_NAME:-casper mesh}"
          CA_DURATION="''${NEBULA_CA_DURATION:-87600h}"
          NODE_DURATION="''${NEBULA_NODE_DURATION:-43800h}"
          CERT_VERSION="''${NEBULA_CERT_VERSION:-2}"
          IDENTITY="''${NEBULA_IDENTITY:-$HOME/.ssh/id_ed25519}"

          die() { printf 'nebula-admin: %s\n' "$*" >&2; exit 1; }
          info() { printf '%s\n' "$*" >&2; }

          REPO="$(git rev-parse --show-toplevel 2>/dev/null)" \
            || die "not inside a git repository"
          SECRETS="$REPO/secrets"

          REG="$(nix --extra-experimental-features 'nix-command flakes' eval --json "$REPO#nebula")" \
            || die "could not read the mesh — new hosts must be staged, flakes ignore untracked files"
          PREFIX="$(jq -r '.prefixLength' <<<"$REG")"
          CIDR="$(jq -r '.cidr' <<<"$REG")"

          WORK=""
          cleanup() {
            if [ -n "$WORK" ] && [ -d "$WORK" ]; then
              find "$WORK" -type f -exec shred -u {} + 2>/dev/null || true
              rm -rf "$WORK"
            fi
          }
          trap cleanup EXIT
          workdir() {
            WORK="$(mktemp -d)"
            chmod 700 "$WORK"
          }

          encrypt() {
            ( cd "$SECRETS" && agenix -i "$IDENTITY" -e "$2" < "$1" >/dev/null )
            git -C "$REPO" add -- "secrets/$2"
          }

          decrypt() {
            ( cd "$SECRETS" && agenix -i "$IDENTITY" -d "$1" )
          }

          have() { [ -f "$SECRETS/$1" ]; }

          hosts() { jq -r '.nodes | keys[]' <<<"$REG"; }

          node_address() { jq -r --arg h "$1" '.nodes[$h].address // empty' <<<"$REG"; }

          node_groups() {
            jq -r --arg h "$1" '(.nodes[$h].groups // []) | join(",")' <<<"$REG"
          }

          load_ca() {
            have nebula-ca.crt.age || die "no CA yet — run: nebula-admin init-ca"
            have nebula-ca.key.age || die "CA certificate present but signing key is missing"
            decrypt nebula-ca.crt.age > "$WORK/ca.crt"
            decrypt nebula-ca.key.age > "$WORK/ca.key"
            chmod 600 "$WORK/ca.crt" "$WORK/ca.key"
          }

          cmd_init_ca() {
            if have nebula-ca.crt.age && [ "''${1:-}" != "--force" ]; then
              die "a CA already exists; re-creating it invalidates every signed node (--force to override)"
            fi
            workdir
            info "Creating CA '$CA_NAME' for $CIDR (valid $CA_DURATION, cert v$CERT_VERSION)"
            nebula-cert ca \
              -name "$CA_NAME" \
              -networks "$CIDR" \
              -duration "$CA_DURATION" \
              -version "$CERT_VERSION" \
              -out-crt "$WORK/ca.crt" \
              -out-key "$WORK/ca.key"
            encrypt "$WORK/ca.crt" nebula-ca.crt.age
            encrypt "$WORK/ca.key" nebula-ca.key.age
            info "Next: nebula-admin sign-all"
          }

          cmd_sign() {
            local force=0
            if [ "''${1:-}" = "--force" ]; then force=1; shift; fi
            local host="''${1:-}"
            [ -n "$host" ] || die "usage: nebula-admin sign [--force] <host>"

            local ip groups
            ip="$(node_address "$host")"
            [ -n "$ip" ] || die "'$host' is not in the registry"
            groups="$(node_groups "$host")"

            if have "nebula-$host.crt.age" && [ "$force" -eq 0 ]; then
              info "$host already signed — skipping (--force to re-issue)"
              return 0
            fi

            workdir
            load_ca

            local args=(
              -ca-crt "$WORK/ca.crt"
              -ca-key "$WORK/ca.key"
              -name "$host"
              -networks "$ip/$PREFIX"
              -duration "$NODE_DURATION"
              -out-crt "$WORK/$host.crt"
              -out-key "$WORK/$host.key"
            )
            if [ -n "$groups" ]; then
              args+=( -groups "$groups" )
            fi

            info "Signing $host -> $ip/$PREFIX ''${groups:+[$groups]}"
            nebula-cert sign "''${args[@]}"
            encrypt "$WORK/$host.crt" "nebula-$host.crt.age"
            encrypt "$WORK/$host.key" "nebula-$host.key.age"
          }

          cmd_sign_all() {
            local -a flags=()
            if [ "''${1:-}" = "--force" ]; then
              flags=( --force )
            fi
            local -a all=()
            mapfile -t all < <(hosts)
            local host
            for host in "''${all[@]}"; do
              cmd_sign "''${flags[@]}" "$host"
            done
          }

          cmd_list() {
            printf '%-20s %-17s %-14s %-11s %s\n' HOST ADDRESS GROUPS ROLE CERTIFICATE
            local -a all=()
            mapfile -t all < <(hosts)
            local host ip groups role status
            for host in "''${all[@]}"; do
              ip="$(node_address "$host")/$PREFIX"
              groups="$(node_groups "$host")"
              if [ "$(jq -r --arg h "$host" '.nodes[$h].isLighthouse // false' <<<"$REG")" = "true" ]; then
                role="lighthouse"
              else
                role="node"
              fi
              if have "nebula-$host.crt.age"; then
                workdir
                if decrypt "nebula-$host.crt.age" > "$WORK/c.crt" 2>/dev/null; then
                  status="expires $(nebula-cert print -json -path "$WORK/c.crt" \
                    | jq -r '.[0].details.notAfter' | cut -dT -f1)"
                else
                  status="signed (cannot decrypt with $IDENTITY)"
                fi
                cleanup
              else
                status="not signed"
              fi
              printf '%-20s %-17s %-14s %-11s %s\n' "$host" "$ip" "''${groups:--}" "$role" "$status"
            done
          }

          cmd_rekey() {
            ( cd "$SECRETS" && agenix -i "$IDENTITY" --rekey )
          }

          usage() {
            cat <<'USAGE'
          nebula-admin — nebula mesh PKI

            list                     registry and certificate status per host
            init-ca [--force]        create the mesh CA
            sign [--force] <host>    sign one host from the registry
            sign-all [--force]       sign every host without a certificate
            rekey                    re-encrypt secrets/ after a recipient change
          USAGE
          }

          case "''${1:-}" in
            list)     shift; cmd_list "$@" ;;
            init-ca)  shift; cmd_init_ca "$@" ;;
            sign)     shift; cmd_sign "$@" ;;
            sign-all) shift; cmd_sign_all "$@" ;;
            rekey)    shift; cmd_rekey "$@" ;;
            ""|-h|--help|help) usage ;;
            *)        usage; exit 1 ;;
          esac
        '';
      };
    in
    {
      packages.nebula-admin = nebula-admin;

      apps.nebula-admin = {
        type = "app";
        program = "${nebula-admin}/bin/nebula-admin";
      };
    };
}
