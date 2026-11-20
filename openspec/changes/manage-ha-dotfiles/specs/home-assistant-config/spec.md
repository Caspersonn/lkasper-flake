# Spec Delta

## Purpose

Declarative management of Home Assistant's user configuration files (automations, scenes, scripts, dashboards) from this flake through the NixOS feature module in `modules/services/automation/`, with the repo as the single source of truth and HA UI state limited to runtime registries.

## ADDED Requirements

### Requirement: Automations are repo-managed
The Home Assistant NixOS feature module (`modules/services/automation/home-assistant.nix`) SHALL define all automations as Nix attribute sets in `services.home-assistant.config` and SHALL NOT create or overwrite files under `/var/lib/hass` through activation scripts.

#### Scenario: Rebuild reflects repo automations
- **WHEN** an automation is added, changed, or removed in the module and the kaito host is rebuilt
- **THEN** the running Home Assistant matches the repo definitions after restart

#### Scenario: No activation script writes to the HA config directory
- **WHEN** the kaito configuration is activated
- **THEN** no activation script creates, replaces, or truncates any file under `/var/lib/hass`

### Requirement: Existing BILRESA automations keep behavior
The migration to declarative definitions SHALL preserve the observable behavior of the existing BILRESA bed and bureau automations unchanged.

#### Scenario: Bed remote still controls the bed lamp
- **WHEN** the BILRESA Bed device publishes MQTT action `on`
- **THEN** the bed lamp entity turns on, as before the migration

### Requirement: Scenes and scripts are repo-managed
Scenes and scripts SHALL be defined declaratively in the module config instead of HA UI storage.

#### Scenario: Repo-defined scene is available
- **WHEN** a scene or script is defined in the module and the host is rebuilt
- **THEN** it is available and executable in Home Assistant

### Requirement: Dashboards run in YAML mode
Home Assistant dashboards (lovelace) SHALL run in YAML mode with dashboard definitions provided from the repo, disabling UI dashboard editing.

#### Scenario: Dashboard renders from repo YAML
- **WHEN** the kaito host is rebuilt with dashboard YAML in the repo
- **THEN** the dashboard renders from that YAML and the UI dashboard editor is unavailable

### Requirement: Runtime registries stay out of the repo
Device, entity, area, and auth registries (`.storage`) SHALL remain runtime state on the host and SHALL NOT be managed by this flake.

#### Scenario: Pairing a device needs no repo change
- **WHEN** a new Zigbee device is paired through zigbee2mqtt/ZHA
- **THEN** it is usable in Home Assistant without any change to this repository
