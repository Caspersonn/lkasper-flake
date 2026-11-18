# Tasks

## 1. Pre-migration export (kaito, read-only)

- [x] 1.1 Export current UI state from kaito: copy `/var/lib/hass/.storage` dashboard/scene/script entries worth keeping to a scratch dir outside the repo; record which keys were found. Verify: export dir contains the captured files and a list of exported keys. Result: /tmp/opencode/ha-migration/hass-storage-export.tgz — only `lovelace_dashboards` exists (one registry item: "Map" dashboard, mode storage, url_path `map`, never edited: no content in `.storage/lovelace`, no `scene`, no `script`).
- [x] 1.2 Fetch `/var/lib/hass/automations.yaml` from kaito and diff against the repo-rendered bilresaAutomations to confirm no UI-created automations exist beyond the two BILRESA ones. Verify: diff is empty, or differences are written down and folded into task 2.2/2.3. Result: diff byte-identical (207 lines, exactly the two BILRESA ids).

## 2. Module rework (modules/services/automation/home-assistant.nix)

- [x] 2.1 Convert the two BILRESA automations to attrsets in `services.home-assistant.config.automation` (ids, aliases, trigger ids, payloads, targets, `mode = "restart"` preserved; `value_template` as double-quoted string with the `''` empty-string default), and delete `bilresaAutomations` writeText plus the `homeAssistantAutomations` activationScript. Verify: `nix eval` of the kaito config shows exactly two automations with the expected ids and a correct `value_template`. Result: nix eval confirms 2 automations, 6 trigger ids each, all 12 action branches 1:1 with the old YAML, value_template renders as `{{ value_json.get('action', '') }}`.
- [x] 2.2 Move scenes to `config.scene` and scripts to `config.script` from the task 1.1 export; empty structures if the export holds none. Verify: `nix eval` shows the exported entries (or empty) and pure flake evaluation still succeeds. Result: export held no scenes/scripts — `config.scene = [ ]` and `config.script = { }` in place; eval shows 0 scene items and 0 script keys.
- [x] 2.3 Dashboards in YAML mode via the module's native mechanism (deviation from the original formats.yaml+tmpfiles-for-everything plan; design.md updated in this change): `config.lovelace.mode = "yaml"`, default dashboard content in `services.home-assistant.lovelaceConfig` (module renders + copies `ui-lovelace.yaml` at service start), `dashboards."nixos-lovelace" = null` suppressing the module's duplicate auto-registered dashboard, Map dashboard from the export under `config.lovelace.dashboards.map` with its file rendered via `pkgs.formats.yaml` and symlinked by a single `systemd.tmpfiles` `L+` rule. Verify: `nix eval` shows the lovelace mode/dashboard config, lovelaceConfig views and the tmpfiles rule. Result: eval confirms mode yaml, map registered, nixos-lovelace null (filtered from rendered configuration.yaml), Home/BILRESA view in lovelaceConfig, one L+ rule for dashboards/map.yaml.
- [x] 2.4 Confirm the module keeps the dendritic shape: flat file, `{ inputs, ... }:` wrapper, no `activationScripts` writing under `/var/lib/hass`, no code comments added. Verify: grep of the module shows no activationScripts block and unchanged wrapper. Result: grep confirms wrapper intact on line 1 and no activationScripts in the module; comment inventory vs HEAD shows every pre-existing comment kept except two stale mosquitto `passwordFile` trailing comments (pre-agenix paths), none added.

## 3. Build and VM validation (non-critical first)

- [x] 3.1 Build the kaito host config before deployment. Verify: `nix build` (or `nix flake check`) for the kaito toplevel exits zero. Result: `nix build .#nixosConfigurations.kaito.config.system.build.toplevel` exits 0 → /nix/store/6sh3vf015gr61wjnlywgmlqzqz0id14f-nixos-system-kaito-26.05.20261015.26f4107.
- [ ] 3.2 Boot `nix run .#vm-kaito` and check: HA starts, both BILRESA automations are listed and fire on a simulated MQTT action publish, the default dashboard renders, and the automation/dashboard editors show read-only/YAML-mode behaviour. Verify: each check observed in the VM.

## 4. Deploy and hardware verification

- [ ] 4.1 Deploy to kaito with the repo's normal rebuild flow. Verify: the switch succeeds and HA comes up healthy (no config errors in the log).
- [ ] 4.2 Manual hardware test: press the BILRESA Bed and Burea remotes for on/off, double-press toggle, and brightness hold; confirm the lights and TRETAKT switches respond exactly as before. Verify: observed behaviour matches pre-change behaviour.
- [ ] 4.3 Confirm on kaito: dashboard loads, exported scenes/scripts (if any) work, `.storage` was not modified by the deploy. Verify: manual check on the live instance.

## Workflow follow-up

- Archive the change after tasks 4.1-4.3 pass and the review requirements are satisfied.
- Separately (not this change): quote the `rules.design[2]` scalar in `openspec/config.yaml` so the design rules stop being dropped by the YAML parser.
