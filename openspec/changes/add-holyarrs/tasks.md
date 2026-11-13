# Tasks

## 1. Pre-flight checks on kaito

- [ ] 1.1 Confirm the Nebula and Tailscale interface names with `ip -br link` on kaito and verify `nebula.mesh` and `tailscale0` are listed
- [ ] 1.2 Confirm uid/gid 2000 are free with `getent passwd 2000; getent group 2000` on kaito and verify both print nothing
- [ ] 1.3 Confirm `/data` does not exist yet with `ls -ld /data` on kaito and verify it reports "No such file or directory"

## 2. Shared storage

- [x] 2.1 Create `modules/services/tools/media-storage.nix` (`flake.modules.nixos.media-storage`) with the `media` user/group (uid/gid 2000), `casper` in group `media`, and tmpfiles for `/data` (root 0755), `/data/debrid`, `/data/symlinks`, `/data/media/{movies,tv,music}` (media 2770); verify with `git add` + `nix eval .#nixosConfigurations.kaito.config.systemd.tmpfiles.settings --json` that the entries are present

## 3. Jackett

- [x] 3.1 Create `modules/services/tools/jackett.nix` (`flake.modules.nixos.jackett`) enabling `services.jackett` with `openFirewall = false` and opening 9117 on the Nebula and Tailscale interfaces; verify with `nix eval` that `services.jackett.enable` is true and 9117 is absent from the global `networking.firewall.allowedTCPPorts`

## 4. Decypharr

- [x] 4.1 Create `modules/services/tools/decypharr.nix` (`flake.modules.nixos.decypharr`) with the `cy01/blackhole:v2.7.2` container: host network, `PUID`/`PGID` 2000, `UMASK=002`, `TZ`, volumes `/var/lib/decypharr:/app` and `/data:/data:rshared`, `/dev/fuse`, `SYS_ADMIN`, `apparmor:unconfined`; verify with `nix eval` that the container's `image` and `extraOptions` match
- [x] 4.2 Add a lazy unmount of `/data/debrid` before start and after stop of `docker-decypharr.service`, plus tmpfiles for `/var/lib/decypharr`, and open 8282 on the Nebula and Tailscale interfaces; verify with `nix eval` that `ExecStartPre`/`ExecStopPost` contain the unmount

## 5. HolyArrs

- [x] 5.1 Create `modules/services/tools/holyarrs.nix` (`flake.modules.nixos.holyarrs`) with the `holyarrs/holyarrs:1.0.19` container: host network, `PUID`/`PGID` 2000, `UMASK=002`, `TZ`, `HOLYARRS_FOLLOW_LINKS=1`, `HOLYARRS_SAVE_PATH=/data/symlinks`, `HOLYARRS_ALLOWED_HOSTS` with `kaito.mesh`, volumes `/var/lib/holyarrs:/config` and `/data:/data:rslave`; verify with `nix eval` that the image tag and environment match
- [x] 5.2 Order `docker-holyarrs.service` after `docker-decypharr.service` without a hard dependency, add tmpfiles for `/var/lib/holyarrs`, and open 6262 on the Nebula and Tailscale interfaces; verify with `nix eval` that `after` contains `docker-decypharr.service` and `requires` does not

## 6. Wire into kaito and build

- [x] 6.1 Add `media-storage`, `jackett`, `decypharr` and `holyarrs` to kaito's imports in `modules/hosts/kaito/configuration.nix`; verify `nix build .#nixosConfigurations.kaito.config.system.build.toplevel` succeeds
- [x] 6.2 Verify the other hosts are unaffected: their `config.system.build.toplevel.drvPath` before and after the change are identical
- [x] 6.3 Verify no secret is in the diff: `git diff` contains no tokens, passwords or API keys, and no new `.age` files were added
- [x] 6.4 Show the diff and build result to the user and get explicit approval before committing, pushing or deploying

## 7. Deploy (manual, on kaito)

- [ ] 7.1 Push, copy the closure to kaito and activate with `sudo .../bin/switch-to-configuration switch`; verify `systemctl is-active docker-decypharr docker-holyarrs jackett` prints three times `active`
- [ ] 7.2 Verify existing services survived: `systemctl is-active navidrome docker-aiostreams home-assistant` all `active`, and `https://navidrome.inspiravita.com` and `https://aiostreams.inspiravita.com` still load
- [ ] 7.3 Verify the firewall: `http://kaito.mesh:6262`, `:8282` and `:9117` load from a mesh device, and the same ports on kaito's LAN address time out from a LAN device

## 8. Configure the services (web UIs, manual)

- [ ] 8.1 Decypharr wizard at `http://kaito.mesh:8282`: admin login, Real-Debrid API key, mount type `dfs` at `/data/debrid` with `allow_other`, cache under `/app`, download folder `/data/symlinks`; verify `ls /data/debrid` on the kaito host lists the Real-Debrid folders
- [ ] 8.2 Jackett at `http://kaito.mesh:9117`: add at least one indexer with music categories and note the API key; verify a manual search for a known album returns results in Jackett
- [ ] 8.3 HolyArrs at `http://kaito.mesh:6262`: create the owner account and add library folders `/data/media/movies`, `/data/media/tv`, `/data/media/music`; verify `docker exec holyarrs /holyarrs doctor` reports no errors
- [ ] 8.4 HolyArrs: link Jackett (`http://127.0.0.1:9117`, API key, "Reach the local network" on) and Decypharr as qBittorrent (`127.0.0.1:8282`, Decypharr login); verify both show as connected, and add HolyArrs' category in Decypharr if the connection test asks for it
- [ ] 8.5 Copy `/var/lib/holyarrs/holyarrs.key` (the `/config` root, confirmed in the test VM) into the password manager; verify the stored copy matches with `sha256sum`

## 9. End-to-end tests (manual, on kaito)

- [ ] 9.1 Movie: add a popular movie and grab a cached release; verify a link appears under `/data/symlinks`, then under `/data/media/movies/`, that `readlink -f` resolves into `/data/debrid`, and that `ffprobe` on it reads the stream
- [ ] 9.2 Music: add an artist, set one album to keep up to date and search; verify the tracks appear under `/data/media/music/<Artist>/<Album> (<Year>)/` as links that `ffprobe` can read
- [ ] 9.3 Mount loss: `systemctl restart docker-decypharr` and verify `/data/debrid` comes back on the host and in HolyArrs (`docker exec holyarrs /holyarrs doctor`) without a "Transport endpoint is not connected" error
- [ ] 9.4 Reboot kaito once and verify all three services, `/data/debrid` and the HolyArrs library are back without manual steps
