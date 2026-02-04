{pkgs, ...}:
{
    programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # C/C++ runtime
      stdenv.cc.cc

      # Core GLib/GObject/GIO
      glib
      dbus

      # GTK stack
      gtk3
      atk
      at-spi2-core
      at-spi2-atk
      gdk-pixbuf
      pango
      cairo

      # Audio
      alsa-lib

      # Printing (needed by Electron)
      cups

      # Crypto/Networking
      nss
      nspr
      nssTools

      # Fonts
      fontconfig
      freetype
      expat

      # Graphics & GPU
      mesa
      libdrm
      libglvnd
      libgbm

    ] ++ (with pkgs.xorg; [
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libXcursor
      libXi
      libXrender
      libxcb
      libxkbcommon
    ]);
  };
}
