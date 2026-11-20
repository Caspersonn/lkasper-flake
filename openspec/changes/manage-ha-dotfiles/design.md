# Design

## Context

See proposal.md - Why. Today `modules/services/automation/home-assistant.nix` renders `automations.yaml` with `pkgs.writeText` and copies it into `/var/lib/hass` via `system.activationScripts.homeAssistantAutomations`, while `services.home-assistant.config.automation = "!include automations.yaml"`. Every rebuild clobbers UI edits. Scenes, scripts and dashboards are unmanaged UI state in `/var/lib/hass/.storage`. The NixOS home-assistant module turns `config` attrsets into `configuration.yaml` keys, so anything expressible as YAML can live in the module directly.

Escaping note: the current `value_template` uses `{{ value_json.get('action', ''\) }}` inside a Nix indented string. The `''\)` escape renders as *empty*, so the deployed template is actually `get('action', )` — valid Python (trailing comma), working only because `None` never matches any payload. Plain double-quoted Nix strings make the intended `''` empty-string default trivial and remove the whole escape class.

## Goals / Non-Goals

**Goals:**

- Automations, scenes, scripts and dashboard definitions live as Nix values in the existing module; a `nixos-rebuild switch` fully applies them.
- No `activationScripts` writing into `/var/lib/hass`.

**Non-Goals:**

- Migrating HA to home-manager (it stays a NixOS system service; HM remains for user dotfiles).
- Managing `.storage` runtime state (entity/device/area registries, auth, integrations set up via UI config entries).
- Changing MQTT, Zigbee2MQTT, Ollama, Wyoming or Mosquitto configuration.
- Multi-host rollout: only kaito imports this module today.

## Decisions

### 1. Automations, scenes and scripts as inline attrsets

`config.automation = [ { ... } ]`, `config.scene = [ ... ]`, `config.script = { ... }` in `services.home-assistant.config`. The two BILRESA automations are converted 1:1 from the current YAML, keeping ids, aliases, trigger ids, payloads, `mode = "restart"`, entity targets and device id. `value_template` strings use double-quoted Nix strings; if a future template contains `${`, it must be escaped (`\${`) or the string switched to `'' ''` form.

Alternatives: keeping `!include automations.yaml` with a symlinked store file (rejected: HA treats the file as read-only, UI automation editor writes fail confusingly, and a placement mechanism is still needed — same hack, different wrapper); YAML files imported into Nix (rejected: adds a converter dependency for no benefit over attrsets).

### 2. Dashboards via lovelace YAML mode, native module rendering + store symlinks

`config.lovelace.mode = "yaml"`. The default dashboard content lives in `services.home-assistant.lovelaceConfig` — the nixpkgs home-assistant module renders it to `ui-lovelace.yaml` (via `pkgs.formats.yaml`) and copies it into the config dir at every service start. Extra dashboards (e.g. the Map dashboard recovered from the kaito export) are registered under `config.lovelace.dashboards.<name>`; their content files are rendered with `pkgs.formats.yaml { }` `.generate` and symlinked into `/var/lib/hass/dashboards/` via `systemd.tmpfiles.rules` (`L+` rules pointing at store paths) — the module has no generic extra-file mechanism. The module's auto-registered `dashboards.nixos-lovelace` entry is set to `null` so the sidebar shows only the default dashboard (which reads `ui-lovelace.yaml`) plus the extra dashboards; `null` values are filtered from the rendered `configuration.yaml`.

Rationale: in YAML mode HA never writes these files, so read-only store content is safe; the native `lovelaceConfig` path reuses the module's tested copy mechanism instead of re-implementing it; `tmpfiles` is declarative and idempotent, unlike `activationScripts`.

Alternatives: hand-rendered `ui-lovelace.yaml` via tmpfiles (rejected: duplicates the module's `lovelaceConfig`/`copyLovelaceConfig` mechanism discovered during implementation); keeping `dashboards.nixos-lovelace` (rejected: duplicates the default dashboard in the sidebar); storage mode (rejected: dashboards not repo-managed); raw `.yaml` files in the repo (rejected: needs an import pipeline; `formats.yaml` is the idiomatic NixOS way).

### 3. One module file, dendritic conventions unchanged

Everything stays in `modules/services/automation/home-assistant.nix` — flat file, categorized directory, `{ inputs, ... }:` wrapper, no `mkEnableOption`, git-tracked, discovered by import-tree. A separate dashboard nix file is only split off if the module grows unwieldy. Cross-host: any host importing `home-assistant` gets this behaviour; currently only kaito.

### 4. No code comments

Implementation adds no comments to the Nix code, matching Luca's standing rule for this repo.

## Risks / Trade-offs

- [UI editors for automations/scenes/scripts become read-only; dashboard editor unavailable] → Accepted per proposal. Editing = repo change + rebuild. Dashboard iteration is slower than the UI editor because the file only changes after a rebuild.
- [Dashboard in YAML mode: changes need a rebuild + service restart to appear] → Accepted; documented in the proposal.
- [Orphaned symlink if the map dashboard is removed from config] → the tmpfiles rule disappears with it; a one-time manual `rm` of the stale symlink may be needed on rollback.
- [Template escaping mistakes when converting YAML to Nix strings] → Conversion task verifies the rendered `configuration.yaml` templates against the current deployed ones (extract from kaito or evaluate the old `writeText`) before deploy.
- [Invalid config attrset breaks HA startup on kaito] → VM test first (`nix run .#vm-kaito`, 8192 MiB, includes HA), plus a config check inside the VM before touching kaito.

## Migration Plan

1. Pre-migration export on kaito (read-only, no rebuild): dump `/var/lib/hass/.storage` dashboard/scene/script state that should survive; current `automations.yaml` is known to equal the repo content (the activation script has been clobbering it on every switch), so no surprises expected there.
2. Implement module changes (this change's tasks).
3. Build + evaluate: `nix build` / flake check for the kaito host config.
4. Test in `nix run .#vm-kaito`: HA starts, automations listed, dashboard renders, UI editors read-only as expected.
5. Deploy to kaito with the normal rebuild flow; verify BILRESA remotes still fire the automations (manual hardware test) and the dashboard loads.
6. Rollback: `git revert` + rebuild. Switching `lovelace.mode` back to storage restores the untouched `.storage` dashboards; `.storage` is never deleted by this change.
