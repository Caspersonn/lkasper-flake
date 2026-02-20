# Capability: User Desktop GNOME (macOS Theme)

## ADDED Requirements

### Requirement: WhiteSur GTK Theme Package
The system SHALL provide a NixOS package for the WhiteSur GTK theme that installs theme files for GTK3, GTK4, and libadwaita support.

#### Scenario: GTK theme package builds successfully
- **WHEN** `nix build .#whitesur-gtk` is executed
- **THEN** the derivation builds without errors
- **AND** theme files are installed to `$out/share/themes/WhiteSur-Dark`
- **AND** libadwaita CSS is included

#### Scenario: GTK theme applied to applications
- **WHEN** home-manager configuration is activated
- **THEN** GTK3 applications use WhiteSur-Dark theme
- **AND** GTK4 applications use WhiteSur-Dark theme
- **AND** libadwaita applications respect dark color scheme

### Requirement: WhiteSur Icon Theme Package
The system SHALL provide a NixOS package for WhiteSur icon theme with macOS-like application and system icons.

#### Scenario: Icon theme package builds successfully
- **WHEN** `nix build .#whitesur-icons` is executed
- **THEN** the derivation builds without errors
- **AND** icons are installed to `$out/share/icons/WhiteSur-dark`

#### Scenario: Icons applied to desktop
- **WHEN** home-manager configuration is activated
- **THEN** GNOME Shell uses WhiteSur icons for applications
- **AND** file manager shows WhiteSur icons for files and folders

### Requirement: WhiteSur Cursor Theme Package
The system SHALL provide a NixOS package for WhiteSur cursor theme with macOS-like pointer graphics.

#### Scenario: Cursor theme package builds successfully
- **WHEN** `nix build .#whitesur-cursors` is executed
- **THEN** the derivation builds without errors
- **AND** cursors are installed to `$out/share/icons/WhiteSur-cursors`

#### Scenario: Cursors applied to desktop
- **WHEN** home-manager configuration is activated
- **THEN** GNOME uses WhiteSur cursor theme
- **AND** cursor size is set to 24 pixels (macOS default)

### Requirement: macOS-like Dock Configuration
The system SHALL configure Dash to Dock extension to provide a macOS-like bottom dock with auto-hide behavior.

#### Scenario: Dock positioned at bottom center
- **WHEN** GNOME session starts
- **THEN** dock is visible at bottom of screen
- **AND** dock is horizontally centered
- **AND** dock is floating (not edge-to-edge)

#### Scenario: Dock auto-hide on window overlap
- **WHEN** a window overlaps the dock area
- **THEN** dock hides automatically
- **AND** dock reappears when mouse moves to bottom edge

#### Scenario: Dock only hides on fullscreen
- **WHEN** an application enters fullscreen mode
- **THEN** dock hides completely
- **AND** dock stays visible with normal windows

#### Scenario: Dock icon configuration
- **WHEN** dock is displayed
- **THEN** icon size is 48 pixels
- **AND** running applications show indicator dots
- **AND** pinned applications are displayed

### Requirement: macOS-like Top Bar Configuration
The system SHALL configure GNOME top bar to resemble macOS menu bar with minimal UI elements.

#### Scenario: Top bar shows app menu
- **WHEN** an application is focused
- **THEN** top bar shows application name
- **AND** application menu is available in top bar

#### Scenario: Top bar hides activities button
- **WHEN** GNOME session starts
- **THEN** activities button is hidden
- **AND** logo/icon area is minimized

#### Scenario: Clock centered in top bar
- **WHEN** GNOME session starts
- **THEN** clock is centered in top bar
- **AND** clock format is "24h HH:MM" or "12h h:MM AM/PM"

### Requirement: Window Decoration macOS Style
The system SHALL configure window decorations to match macOS button placement and styling.

#### Scenario: Window buttons on left
- **WHEN** application window is displayed
- **THEN** close, minimize, maximize buttons are on the left
- **AND** button order is close, minimize, maximize (left to right)

### Requirement: Font Configuration macOS Style
The system SHALL configure system fonts to use Inter (SF Pro alternative) for interface and monospace fonts.

#### Scenario: System fonts configured
- **WHEN** GNOME session starts
- **THEN** interface font is Inter Regular 10pt
- **AND** document font is Inter Regular 11pt
- **AND** monospace font is JetBrains Mono 10pt

### Requirement: GNOME Shell Theme Integration
The system SHALL enable User Themes extension and apply WhiteSur GNOME Shell theme for top bar and overview styling.

#### Scenario: Shell theme applied
- **WHEN** GNOME session starts
- **THEN** User Themes extension is enabled
- **AND** GNOME Shell theme is set to WhiteSur-Dark

### Requirement: Theme Activation
The system SHALL use home.activation script to symlink theme files from nix store to GNOME's expected locations.

#### Scenario: Theme files symlinked on activation
- **WHEN** `home-manager switch` is executed
- **THEN** GTK theme is symlinked to `~/.themes/WhiteSur-Dark`
- **AND** icon theme is symlinked to `~/.icons/WhiteSur-dark`
- **AND** cursor theme is symlinked to `~/.icons/WhiteSur-cursors`
- **AND** GNOME Shell theme is symlinked to `~/.themes/WhiteSur-Dark/gnome-shell`

#### Scenario: Existing symlinks are not broken
- **WHEN** `home-manager switch` is executed multiple times
- **THEN** existing symlinks are replaced safely
- **AND** no duplicate or broken symlinks exist

### Requirement: Declarative dconf Configuration
The system SHALL use dconf.settings to configure all GNOME appearance and behavior settings declaratively.

#### Scenario: dconf settings applied on activation
- **WHEN** `home-manager switch` is executed
- **THEN** GTK theme setting is applied via dconf
- **AND** icon theme setting is applied via dconf
- **AND** cursor theme setting is applied via dconf
- **AND** font settings are applied via dconf
- **AND** extension settings are applied via dconf

#### Scenario: dconf settings persist across reboots
- **WHEN** system is rebooted
- **THEN** all theme settings remain configured
- **AND** no manual re-application is needed

### Requirement: GNOME Extensions Management
The system SHALL install and enable required GNOME extensions via home-manager for macOS-like functionality.

#### Scenario: Required extensions installed
- **WHEN** home-manager configuration is activated
- **THEN** Dash to Dock extension is installed and enabled
- **AND** User Themes extension is installed and enabled
- **AND** Just Perfection extension is installed and enabled

#### Scenario: Extensions configured automatically
- **WHEN** GNOME session starts
- **THEN** extension settings are applied from dconf
- **AND** no manual configuration via Extensions app is needed

### Requirement: Build Verification
The system SHALL ensure home-manager configuration builds successfully with all theme packages.

#### Scenario: Home-manager builds for antonia@sakura
- **WHEN** `home-manager build --flake .#antonia@sakura` is executed
- **THEN** build completes without errors
- **AND** all theme packages are included in closure
- **AND** activation script is generated

#### Scenario: Configuration follows dendritic pattern
- **WHEN** module is evaluated by flake-parts
- **THEN** module is wrapped with `flake.modules.homeManager.gnome`
- **AND** module exports proper home-manager configuration
- **AND** no evaluation errors occur
