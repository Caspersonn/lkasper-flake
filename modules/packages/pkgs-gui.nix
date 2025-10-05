{ pkgs, unstable, ... }:

{
  environment.systemPackages = with pkgs; [

    # GUI Applications - Office & Productivity
    libreoffice-qt6-fresh
    onlyoffice-bin
    signal-desktop
    unstable.jan
    unstable.newelle

    # GUI Applications - Media & Entertainment
    obs-studio
    spotify
    video-trimmer

    # GUI Applications - Development
    pgadmin4-desktopmode
    cypress

    # GUI Applications - Security & Utilities
    bitwarden-desktop
    firejail
    filezilla
    discord
    ddcutil
    winetricks
  ];
}
