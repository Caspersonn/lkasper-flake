# Proposal

## Why

Home Assistant's configuration is split between this repo and runtime state on kaito: `automations.yaml` is written by an activation script that silently overwrites any UI-edited automations on every rebuild, and scenes, scripts, and dashboards exist only as UI state in `/var/lib/hass/.storage`, outside version control. Managing HA's config files from this repo makes the repo the single source of truth and removes the clobbering hack.

## What Changes

- Replace the `bilresaAutomations` `writeText` + `system.activationScripts` hack with automations defined as Nix attribute sets in `services.home-assistant.config`; delete the activation script.
- Add repo management for scenes, scripts, and dashboards (lovelace YAML mode), with a one-time migration of whatever currently exists as UI state on kaito.
- After migration, the repo is the only source of truth for automations, scenes, scripts, and dashboards; UI editing of these areas is given up by design. `.storage` registries (devices, entities, areas, auth) remain runtime state and out of scope.

**BREAKING**: any automations, scenes, scripts, or dashboards created or edited via the HA UI on kaito are dropped or become read-only after migration. They must be exported before the first rebuild or re-created in the repo.

## Capabilities

### New Capabilities
- `home-assistant-config`: declarative management of Home Assistant's user configuration files (automations, scenes, scripts, dashboards) from this repo through the NixOS `services.home-assistant` module.

### Modified Capabilities

None: `flake-structure`, `nixos-configurations`, and `user-desktop-gnome` requirements are unaffected.

## Impact

- Code: `modules/services/automation/home-assistant.nix` (the only module touched; dashboard YAML may live alongside it in the same directory).
- Hosts: kaito only — the single host importing the `home-assistant` module (x86_64). No other host is affected.
- Home-manager: not affected; this change deliberately stays at the NixOS level.
- Dendritic pattern: unchanged — no new module, no option flags; all edits stay inside the existing `home-assistant` feature module.
- Runtime: `/var/lib/hass/automations.yaml` and lovelace `.storage` entries on kaito are superseded by repo-managed config.
