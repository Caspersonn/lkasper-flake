# Change: Add macOS-like GNOME Desktop Theme for Antonia

## Why
The current GNOME configuration for user Antonia is minimal (empty module). We need a comprehensive macOS-inspired desktop environment using WhiteSur GTK theme suite to provide a polished, production-ready GNOME setup that mirrors macOS Big Sur aesthetics and workflow.

## What Changes
- Add WhiteSur GTK theme package (NixOS derivation)
- Add WhiteSur icon theme package
- Add WhiteSur cursor theme package
- Configure GNOME Shell with macOS-like layout (dock, top bar, animations)
- Configure dconf settings for macOS-inspired behavior
- Install required GNOME extensions (Dash to Dock, Just Perfection, User Themes)
- Configure libadwaita theming
- Add SF Pro font family support
- Set up macOS-inspired wallpapers
- Enable Kvantum theme support for Qt applications

## Impact
- Affected specs: `user-desktop-gnome` (new capability)
- Affected code: 
  - `modules/users/antonia/desktop/gnome/default.nix` (currently empty, will be populated)
  - New packages: `modules/nix/whitesur-gtk-package.nix`, `modules/nix/whitesur-icons-package.nix`, `modules/nix/whitesur-cursors-package.nix`
- Dependencies: Requires system-level GNOME configuration (`modules/programs/desktop/gnome.nix`) to be enabled by user
- User impact: Complete visual transformation to macOS-like experience on GNOME
