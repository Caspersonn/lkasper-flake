# Tasks

Checked items below record the implemented acquisition baseline only; they do not verify the expanded playback or no-clickops requirements. New implementation and deployment are blocked on section 0. Comments in code are not needed.

## 0. Resolve the expanded implementation design

- [x] 0.1 Record user selections in `design.md`: Soundspan conditional on verified HolyArrs integration, Jellyfin for movies/TV, and Casper's client profiles on technative-casper, gaming-casper and personal-casper; verified against the user's confirmations and each host's declared `casper@<hostname>` profile
- [ ] 0.2 Implement and verify the approved custom Soundspan-to-HolyArrs provider, availability refresh and automatic playback against pinned versions; `design.md` records Soundspan revision `207d412ab380de7e4e0af11daecd6a2f82f86857` and HolyArrs `1.0.19` source revision `3a710bab9e157dc68385da4f3f7e96b957f6617e`, native request contracts and the provider-patch direction; remains open pending the acquisition/bootstrap gates, concrete implementation tasks, contract tests and end-to-end verification
- [ ] 0.3 Establish a subscription-free music acquisition source, supported HolyArrs/downloader integration and storage policy; the user selected Transmission plus Jackett with local files and required VPN isolation, recorded in `design.md`; resolve the VPN provider/tunnel, specific indexers and retention policy, then verify fail-closed peer egress, tunneled DNS, no IPv6 bypass and a VPN exit IP, without routing unrelated services through the VPN or using paid Real-Debrid as the sole music path
- [ ] 0.4 Establish unattended owner/API-key bootstrap, settings reconciliation and protected key recovery for each selected service at its pinned version; verify no procedure requires a wizard, manually obtained UI key or direct database editing
- [ ] 0.5 Once application, acquisition and bootstrap design decisions are resolved, add concrete application-specific implementation tasks and verification commands, including the custom provider work tracked by 0.2; full integration/end-to-end verification follows implementation, not task creation; verify the design, proposal, spec and tasks describe the same selected stack before applying

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
- [x] 6.2 Verify the original acquisition baseline leaves other hosts unaffected: their `config.system.build.toplevel.drvPath` before and after that baseline are identical; expanded client changes require fresh verification
- [x] 6.3 Verify the original acquisition baseline adds no tokens, passwords, API keys or `.age` files; the expanded requirement permits encrypted agenix inputs and requires a fresh plaintext-secret check
- [x] 6.4 Show the diff and build result to the user and get explicit approval before committing, pushing or deploying

## 7. Deploy on kaito after declarative provisioning and VM acceptance

- [ ] 7.1 Push, copy the closure to kaito and activate with `sudo .../bin/switch-to-configuration switch`; verify `systemctl is-active docker-decypharr docker-holyarrs jackett` prints three times `active`
- [ ] 7.2 Verify existing services survived: `systemctl is-active navidrome docker-aiostreams home-assistant` all `active`, and `https://navidrome.inspiravita.com` and `https://aiostreams.inspiravita.com` still load
- [ ] 7.3 Verify the firewall: `http://kaito.mesh:6262`, `:8282` and `:9117` load from a mesh device, and the same ports on kaito's LAN address time out from a LAN device

## 8. Declarative service provisioning (blocked on section 0)

- [ ] 8.1 Provision Decypharr credentials, mount settings, `allow_other`, cache and `/data/symlinks` declaratively; verify a fresh instance is configured without a wizard and the host can read `/data/debrid`
- [ ] 8.2 Provision Jackett indexers, categories and API access declaratively; verify a configured source returns album releases and two activations do not duplicate sources
- [ ] 8.3 Provision HolyArrs owner/API access and library folders declaratively; verify a fresh instance needs no account wizard and `docker exec holyarrs /holyarrs doctor` reports no errors
- [ ] 8.4 Provision HolyArrs source/downloader connections and downloader categories declaratively; verify both connections work and repeated activation preserves library records without duplicate integrations
- [ ] 8.5 Provision secret inputs through agenix/runtime files and implement protected automated recovery for state and `/var/lib/holyarrs/holyarrs.key`; verify a clean restore decrypts credentials without manual copying and plaintext secrets are absent from Git, store paths and logs

## 9. Acquisition tests after disposable-VM acceptance

- [ ] 9.1 Movie: add a popular movie and grab a cached release; verify a link appears under `/data/symlinks`, then under `/data/media/movies/`, that `readlink -f` resolves into `/data/debrid`, and that `ffprobe` on it reads the stream
- [ ] 9.2 Music: request an unowned album through the selected music application using the subscription-free acquisition path; verify HolyArrs receives the request and imported tracks are readable according to the selected storage policy
- [ ] 9.3 Mount loss: `systemctl restart docker-decypharr` and verify `/data/debrid` comes back on the host and in HolyArrs (`docker exec holyarrs /holyarrs doctor`) without a "Transport endpoint is not connected" error
- [ ] 9.4 Reboot kaito once and verify all three services, `/data/debrid` and the HolyArrs library are back without manual steps

## 10. Expanded stack acceptance (blocked on section 0 and concrete implementation tasks)

- [ ] 10.1 Build affected NixOS and Home Manager configurations with pure evaluation before deployment; record actual commands and successful results, and verify hosts without selected client profiles remain unchanged by this change
- [ ] 10.2 Test a clean disposable VM with runtime secrets: activate twice and restart services; verify accounts, integrations and paths are ready without browser setup, manual API calls or database edits, with no duplicate integrations or loss of user state
- [ ] 10.3 Recreate a selected Home Manager profile; verify supported client packages and non-secret dotfiles are restored from repository-managed configuration without manual copying, while shared server state stays NixOS-owned
- [ ] 10.4 Verify an unowned music recommendation can be requested, acquired through HolyArrs and played automatically after import without switching to an administration UI; verify pending/failure states and retry, with no paid subscription or YouTube fallback
- [ ] 10.5 Verify the separate movie/TV application plays an acquired item, and Navidrome/AIOStreams and original libraries remain available throughout testing; record acceptance before proposing decommissioning
- [ ] 10.6 After deployment approval and successful VM tests, perform host-specific checks on kaito and selected client hardware; verify playback, private access, restart and rollback without deleting existing state or media
