{ ... }:
{
  # Declarative glue for settings the music apps only keep in their own
  # databases. Idempotent: safe on every boot and rebuild. Re-run manually with
  #   systemctl restart music-provision
  flake.modules.nixos.navidrome = { config, lib, pkgs, ... }:
    let
      lidarrUrl = "http://127.0.0.1:8686";
      jellyfinUrl = "http://127.0.0.1:8096";
      aurralUrl = "http://127.0.0.1:${toString config.services.aurral.port}";
      navidromeUrl = "http://127.0.0.1:4533";
      slskdUrl = "http://127.0.0.1:5030";

      lidarrRoot = "/mnt/audio/music/lidarr";
      jellyfinPaths = [ "/mnt/audio/music" config.services.aurral.environment.DOWNLOAD_FOLDER ];

      provision = pkgs.writeShellApplication {
        name = "music-provision";
        runtimeInputs = with pkgs; [ curl jq coreutils ];
        # provision_* functions are dispatched by name.
        excludeShellChecks = [ "SC2329" ];
        text = ''
          log() { echo "music-provision[$section]: $*" >&2; }

          wait_for() {
            for _ in $(seq 1 150); do
              curl -fsS -o /dev/null "$1" && return 0
              sleep 2
            done
            log "timed out waiting for $1"
            return 1
          }

          json() { curl -fsS -H 'Content-Type: application/json' "$@"; }

          # ---------------------------------------------------------------- Lidarr
          lidarr() {
            local method=$1 path=$2
            shift 2
            json -X "$method" -H "X-Api-Key: $LIDARR_API_KEY" "${lidarrUrl}/api/v1$path" "$@"
          }

          provision_lidarr() {
            wait_for "${lidarrUrl}/ping"

            if ! lidarr GET /rootfolder | jq -e --arg p "${lidarrRoot}" \
                'any(.[]; (.path | rtrimstr("/")) == $p)' >/dev/null; then
              local qp mp
              qp=$(lidarr GET /qualityprofile | jq '.[0].id')
              mp=$(lidarr GET /metadataprofile | jq '(map(select(.name == "Standard"))[0] // .[0]).id')
              jq -n --arg p "${lidarrRoot}" --argjson qp "$qp" --argjson mp "$mp" '{
                  name: "Music", path: $p,
                  defaultQualityProfileId: $qp, defaultMetadataProfileId: $mp,
                  defaultMonitorOption: "all", defaultNewItemMonitorOption: "all",
                  defaultTags: []
                }' | lidarr POST /rootfolder -d @- >/dev/null
              log "created root folder ${lidarrRoot}"
            fi

            # Forms login user (method itself is set via LIDARR__AUTH__* env).
            local host
            host=$(lidarr GET /config/host)
            jq --arg u "$LIDARR_USERNAME" --arg p "$LIDARR_PASSWORD" \
                '.username = $u | .password = $p | .passwordConfirmation = $p' <<<"$host" \
              | lidarr PUT "/config/host/$(jq -r .id <<<"$host")" -d @- >/dev/null
            log "ok"
          }

          # -------------------------------------------------------------- Jellyfin
          jf_client='MediaBrowser Client="music-provision", Device="kaito", DeviceId="music-provision", Version="1.0"'
          jf_token=""
          jf_user=""

          jf() {
            local method=$1 path=$2
            shift 2
            json -X "$method" -H "Authorization: $jf_client, Token=\"$jf_token\"" "${jellyfinUrl}$path" "$@"
          }

          jellyfin_login() {
            local login
            login=$(jq -n --arg u "$JELLYFIN_USERNAME" --arg p "$JELLYFIN_PASSWORD" '{Username: $u, Pw: $p}' \
              | json -X POST -H "Authorization: $jf_client" "${jellyfinUrl}/Users/AuthenticateByName" -d @-)
            jf_token=$(jq -r .AccessToken <<<"$login")
            jf_user=$(jq -r .User.Id <<<"$login")
            [ -n "$jf_token" ] && [ "$jf_token" != null ]
          }

          provision_jellyfin() {
            wait_for "${jellyfinUrl}/System/Info/Public"

            jellyfin_login

            if ! jf GET /Library/VirtualFolders | jq -e 'any(.[]; .Name == "Music")' >/dev/null; then
              jf POST "/Library/VirtualFolders?name=Music&collectionType=music&refreshLibrary=true&${
                lib.concatMapStringsSep "&" (p: "paths=${p}") jellyfinPaths
              }" -d '{"LibraryOptions":{}}' >/dev/null
              log "created Music library"
            fi
            log "ok"
          }

          jellyfin_api_key() {
            local key
            key=$(jf GET /Auth/Keys | jq -r '[.Items[] | select(.AppName == "Aurral")][0].AccessToken // empty')
            if [ -z "$key" ]; then
              jf POST "/Auth/Keys?app=Aurral" >/dev/null
              key=$(jf GET /Auth/Keys | jq -r '[.Items[] | select(.AppName == "Aurral")][0].AccessToken')
            fi
            echo "$key"
          }

          # ---------------------------------------------------------------- Aurral
          provision_aurral() {
            wait_for "${aurralUrl}/api/health"

            local token want
            token=$(jq -n --arg u "$AURRAL_USERNAME" --arg p "$AURRAL_PASSWORD" '{username: $u, password: $p}' \
              | json -X POST "${aurralUrl}/api/auth/login" -d @- | jq -r .token)

            want=$(jq -n --arg lk "$LIDARR_API_KEY" --arg sk "$SLSKD_API_KEY" '{
                lidarr: {url: "${lidarrUrl}", apiKey: $lk},
                slskd: {enabled: true, url: "${slskdUrl}", apiKey: $sk},
                ytdlp: {enabled: false}
              }')

            if jellyfin_login 2>/dev/null; then
              local jf_key
              jf_key=$(jellyfin_api_key)
              want=$(jq --arg k "$jf_key" --arg id "$jf_user" \
                '.jellyfin = {url: "${jellyfinUrl}", apiKey: $k, userId: $id}' <<<"$want")
            else
              log "skipping Jellyfin link: cannot log in to Jellyfin as $JELLYFIN_USERNAME"
            fi

            if curl -fsS -G "${navidromeUrl}/rest/ping.view" -d v=1.16.1 -d c=music-provision -d f=json \
                --data-urlencode "u=$NAVIDROME_USERNAME" --data-urlencode "p=$NAVIDROME_PASSWORD" \
                | jq -e '."subsonic-response".status == "ok"' >/dev/null; then
              want=$(jq --arg u "$NAVIDROME_USERNAME" --arg p "$NAVIDROME_PASSWORD" \
                '.navidrome = {url: "${navidromeUrl}", username: $u, password: $p}' <<<"$want")
            else
              log "skipping Navidrome link: create admin user '$NAVIDROME_USERNAME' in Navidrome first"
            fi

            # Only send integrations whose fields differ, so restarts don't trigger resyncs.
            local patch
            patch=$(curl -fsS -H "Authorization: Bearer $token" "${aurralUrl}/api/settings" \
              | jq --argjson want "$want" '.integrations as $cur | $want
                  | with_entries(select(.key as $k | .value | to_entries
                      | all(.value == $cur[$k][.key]) | not))')

            if [ "$patch" != "{}" ]; then
              jq -n --argjson i "$patch" '{integrations: $i}' \
                | json -X POST -H "Authorization: Bearer $token" "${aurralUrl}/api/settings" -d @- >/dev/null
              log "updated integrations: $(jq -r 'keys | join(", ")' <<<"$patch")"
            fi
            log "ok"
          }

          # Each section runs in its own process so `set -e` holds inside it and
          # one failing app doesn't block the others.
          section=''${1:-all}
          if [ "$section" != all ]; then
            "provision_$section"
            exit
          fi

          failed=0
          for s in lidarr jellyfin aurral; do
            "$0" "$s" || { failed=1; echo "music-provision: $s failed" >&2; }
          done
          exit "$failed"
        '';
      };

      apps = [ "lidarr.service" "jellyfin.service" "aurral.service" "navidrome.service" "slskd.service" ];
    in
    {
      systemd.services.music-provision = {
        description = "Provision Lidarr, Jellyfin, slskd and Navidrome links into Aurral";
        wantedBy = [ "multi-user.target" ];
        wants = apps;
        after = apps;
        restartTriggers = [ provision ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe provision;
          EnvironmentFile = with config.age.secrets; [
            music-lidarr-api.path
            music-credentials.path
            music-slskd.path
          ];
          TimeoutStartSec = "15min";
          DynamicUser = true;
          # Systemd reads EnvironmentFile as root, so no file access is needed.
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          NoNewPrivileges = true;
        };
      };
    };
}
