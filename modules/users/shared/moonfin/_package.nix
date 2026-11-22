{ lib, stdenv, fetchurl, buildFHSEnv, makeDesktopItem }:
let
  version = "3.1.0";
  bundle = stdenv.mkDerivation {
    pname = "moonfin-bundle";
    inherit version;
    src = fetchurl {
      url = "https://github.com/Moonfin-Client/Moonfin-Core/releases/download/${version}/Moonfin_Linux_v${version}.tar.gz";
      sha256 = "0f32dalrwi18s503hyz375snn3fx59ls179d3ndccks9g7sbsagf";
    };
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p "$out/share/moonfin"
      cp -a . "$out/share/moonfin/"
    '';
  };
  desktop = makeDesktopItem {
    name = "moonfin";
    desktopName = "Moonfin";
    exec = "moonfin %U";
    categories = [ "AudioVideo" "Video" ];
    terminal = false;
  };
in
buildFHSEnv {
  name = "moonfin";
  targetPkgs = pkgs: with pkgs; [
    gtk3 glib webkitgtk_4_1 sqlite libsecret libGL libxkbcommon
    xdg-user-dirs xdg-utils alsa-lib pulseaudio fontconfig freetype
    glibc gsettings-desktop-schemas coreutils gawk gnugrep
    atk cairo openssl libdrm libepoxy mesa libgbm gdk-pixbuf harfbuzz
    libjack2 pango pipewire librsvg systemd libxcb libXScrnSaver libXv wayland
  ];
  runScript = "${bundle}/share/moonfin/moonfin";
  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    cp ${desktop}/share/applications/moonfin.desktop "$out/share/applications/"
  '';
  meta = {
    description = "Moonfin client for Jellyfin with integrated discovery and requests";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "moonfin";
  };
}
