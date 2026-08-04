{ ... }: {
  # Photoshop 2021 under a patched Wine, in its own prefix.
  #
  # Not imported by any host yet — add `photoshop` to a host's module list to
  # enable it. Installing Photoshop itself is a manual, one-time step that
  # needs your own Adobe installer; see `photoshop-setup --help`.
  flake.modules.nixos.photoshop = { pkgs, ... }:
    let
      prefix = "$HOME/.local/share/wine-adobe";

      # Wine 11.12 (wine-devel series, matching the 11.10 base the patches were
      # written against) plus three fixes the Adobe CC 2021 installer and
      # Photoshop 2021 need. All three are absent from stock and staging Wine as
      # of 11.12, verified against the release tarball:
      #
      #   libs/xml2  Adobe's installer manifests embed <?xml?> declarations
      #              inside elements. Windows MSXML tolerates this, libxml2
      #              rejects it as fatal, so the installer cannot parse its own
      #              manifests. Upstream MR !10025 took the msxml3/CDATA route
      #              instead and was closed unmerged.
      #   msvcrt     _FindAndUnlinkFrame walked the frame list without a NULL
      #              guard, so an empty list crashed Photoshop on startup.
      #              Never submitted upstream.
      #   d2d1       DrawGeometryRealization only handled command-list targets
      #              and silently did nothing on bitmap targets, leaving parts
      #              of the UI unpainted. Never submitted upstream.
      #   dwrite     create_matching_font dereferenced a NULL font collection.
      #              Wine logged "ignoring exception c0000005" and unwound
      #              without releasing the faulting thread's critical section,
      #              so Photoshop deadlocked instead of crashing: the New
      #              Document dialog never opened and the UI stopped
      #              responding. Written here against 11.12; the upstream fork
      #              carried the same fix as a binary trampoline into
      #              dwrite.dll, whose offsets no longer match this version.
      #
      # The first three patches are taken from
      # PhialsBasement/wine-adobe-installers (a three-commit fork of Wine
      # 11.10) and vendored here, since that fork can rewrite history or
      # disappear.
      wine-adobe = pkgs.unstable.wineWow64Packages.unstableFull.overrideAttrs
        (old: {
          pname = "wine-adobe";
          patches = (old.patches or [ ]) ++ [
            ./photoshop-patches/libs-xml2-embedded-xml-declarations.patch
            ./photoshop-patches/msvcrt-findandunlinkframe-null-deref.patch
            ./photoshop-patches/d2d1-geometry-realizations-bitmap-targets.patch
            ./photoshop-patches/dwrite-create-matching-font-null-collection.patch
          ];
        });

      # Wine pinned to the Adobe prefix, so it can never touch ~/.wine.
      # winemenubuilder is disabled to stop Adobe scattering .desktop files.
      wine-adobe-run = pkgs.writeShellScriptBin "wine-adobe" ''
        export WINEPREFIX="${prefix}"
        export WINEDLLOVERRIDES="winemenubuilder.exe=d''${WINEDLLOVERRIDES:+;$WINEDLLOVERRIDES}"
        exec ${wine-adobe}/bin/wine "$@"
      '';

      photoshop-setup = pkgs.writeShellScriptBin "photoshop-setup" ''
        set -euo pipefail

        if [ "''${1:-}" = "--help" ] || [ $# -eq 0 ]; then
          cat <<'USAGE'
        photoshop-setup /run/media/casper/21_06_2025/Adobe-Photoshop-2021/Files\ Patch\ (\ Crack)/photoshop.exe

        Creates the Wine prefix at ~/.local/share/wine-adobe, installs the
        libraries Photoshop needs, then runs your Adobe installer.

        You supply the installer: an Adobe CC 2021 offline installer directory
        containing Set-up.exe alongside its packages/ and products/ folders.
        Point this script at that Set-up.exe.

        Re-running is safe; prefix creation and winetricks verbs are skipped if
        already done.
        USAGE
          exit 0
        fi

        setup_exe="$1"
        [ -f "$setup_exe" ] || { echo "not a file: $setup_exe" >&2; exit 1; }

        export WINEPREFIX="${prefix}"
        export WINEDLLOVERRIDES="winemenubuilder.exe=d"
        wine=${wine-adobe}/bin/wine

        if [ ! -d "$WINEPREFIX" ]; then
          echo "==> creating 64-bit prefix at $WINEPREFIX"
          mkdir -p "$(dirname "$WINEPREFIX")"
          "$wine" wineboot --init
          "${wine-adobe}/bin/wineserver" -w
        fi

        if [ ! -e "$WINEPREFIX/.verbs-installed" ]; then
          echo "==> installing support libraries via winetricks"
          # WINE64 must be set explicitly. winetricks probes the arch of the
          # wine binary with file(1), but nixpkgs ships bin/wine as a wrapper
          # script, so the probe returns nothing and WoW64 style comes out
          # "unknown". It then hunts for a wine64 binary, which wineWow64
          # builds do not have (one 64-bit `wine` runs both architectures),
          # leaves WINE_ARCH empty, and dies on the first w_expand_env with
          # "cmd.exe /c echo '%AppData%' returned empty string". Presetting
          # WINE64 short-circuits that detection.
          # dxvk routes Photoshop's D3D through Vulkan instead of wined3d's
          # OpenGL translation, which is the difference between a sluggish
          # canvas and a usable one on an integrated GPU.
          # tahoma is what Wine's dwrite falls back to by name when a font
          # lookup fails; win10 is required because Photoshop 2021 rejects
          # anything below Windows 10 1809 in its RtlGetVersion check.
          WINE="$wine" WINE64="$wine" WINESERVER="${wine-adobe}/bin/wineserver" \
            ${pkgs.winetricks}/bin/winetricks -q \
            atmlib corefonts tahoma fontsmooth=rgb gdiplus msxml3 msxml6 \
            vcrun2019 dxvk win10
          touch "$WINEPREFIX/.verbs-installed"
        fi

        if [ ! -e "$WINEPREFIX/.dpi-set" ]; then
          # Wine defaults to 96 DPI, which renders Photoshop's UI unusably
          # small on a HiDPI panel. 144 (150%) is a sane starting point; edit
          # both values or run `wine-adobe winecfg` to taste. Wine reads
          # Software\Wine\Fonts; Control Panel\Desktop is kept in sync because
          # some apps read that one instead.
          echo "==> setting prefix DPI to 144"
          reg=$(mktemp)
          printf 'Windows Registry Editor Version 5.00\r\n\r\n[HKEY_CURRENT_USER\\Software\\Wine\\Fonts]\r\n"LogPixels"=dword:00000090\r\n\r\n[HKEY_CURRENT_USER\\Control Panel\\Desktop]\r\n"LogPixels"=dword:00000090\r\n' > "$reg"
          "$wine" regedit "$reg"
          rm -f "$reg"
          touch "$WINEPREFIX/.dpi-set"
        fi

        echo "==> running $setup_exe"
        exec "$wine" "$setup_exe"
      '';

      # Win32 helper that hides the two windows Wine gets wrong. Built for
      # Windows because it has to call ShowWindow inside the prefix.
      pswin = pkgs.runCommand "pswin.exe" {
        nativeBuildInputs = [ pkgs.pkgsCross.mingwW64.buildPackages.gcc ];
      } ''
        mkdir -p "$out/bin"
        x86_64-w64-mingw32-gcc -O2 -o "$out/bin/pswin.exe" \
          ${./photoshop-patches/pswin.c} -luser32
      '';

      photoshop = pkgs.writeShellScriptBin "photoshop" ''
        export WINEPREFIX="${prefix}"
        export WINEDLLOVERRIDES="winemenubuilder.exe=d"

        # Photoshop's embedded IE control sits in a hot message loop that emits
        # an unimplemented-event fixme on every iteration: roughly 18,000 lines
        # a second, 3 GB of log in an hour, all of it synchronous writes on a
        # thread Photoshop is waiting on. Silencing the channels costs nothing
        # diagnostically here and removes the I/O entirely. Override on the
        # command line (WINEDEBUG=+seh photoshop) when debugging.
        export WINEDEBUG="''${WINEDEBUG:--all}"
        psdir="$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop 2021"
        exe="$psdir/Photoshop.exe"
        if [ ! -f "$exe" ]; then
          echo "Photoshop is not installed in $WINEPREFIX." >&2
          echo "Run: photoshop-setup /path/to/Set-up.exe" >&2
          exit 1
        fi

        # Post-install prefix fixes. These need Photoshop's files in place, so
        # they cannot live in photoshop-setup's pre-install section, and the
        # marker keeps them off the hot path on every later launch.
        if [ ! -e "$WINEPREFIX/.tweaks-applied" ]; then
          # The CEP start panel renders as a blank white "Loading..." pane
          # under Wine. Disabling the extension makes Photoshop fall through to
          # its native welcome screen, which draws correctly.
          ccx="$psdir/Required/CEP/extensions/com.adobe.ccx.start"
          if [ -d "$ccx" ]; then
            mv "$ccx" "$ccx.disabled"
            echo "==> disabled CEP start panel"
          fi

          # Scrollbar rails. Wine's user32 fallback picks a dithered 55AA brush
          # when COLOR_3DHILIGHT equals COLOR_WINDOW, which renders the rail
          # solid white; nudging ButtonHilight off pure white breaks that
          # equality so COLOR_SCROLLBAR is used instead. 57 57 57 matches
          # Photoshop's own dark rail. This does not affect the OWL.MenuBar
          # white strip, which is a separate bug that pswin handles.
          reg=$(mktemp)
          printf 'Windows Registry Editor Version 5.00\r\n\r\n[HKEY_CURRENT_USER\\Control Panel\\Colors]\r\n"ButtonHilight"="254 254 254"\r\n"Scrollbar"="57 57 57"\r\n' > "$reg"
          ${wine-adobe}/bin/wine regedit "$reg" >/dev/null 2>&1 || true
          rm -f "$reg"

          touch "$WINEPREFIX/.tweaks-applied"
        fi

        # Force Photoshop's legacy New Document dialog. The modern one is a web
        # view (class EmbeddedWB) that never finishes loading without an Adobe
        # session, and it covers the native dialog underneath. Preferences >
        # General > "Use legacy 'New Document' interface" sets this, but that
        # pane is itself a dialog, so it cannot be reached when dialogs are the
        # broken thing.
        #
        # Prefs.psp is Photoshop's descriptor format: a u32 key length, the key,
        # a four-character type tag written little-endian ("loob" for bool),
        # then the value. The tag is checked before writing so a layout change
        # in a future Photoshop build makes this skip rather than corrupt the
        # file. Reasserted on every launch because Photoshop rewrites its prefs
        # on exit.
        for prefs in "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/Adobe/"Adobe Photoshop 2021"/"Adobe Photoshop 2021 Settings"/"Adobe Photoshop 2021 Prefs.psp"; do
          [ -f "$prefs" ] || continue
          off=$(grep -abo useLegacy "$prefs" 2>/dev/null | head -1 | cut -d: -f1)
          [ -n "$off" ] || continue
          [ "$(dd if="$prefs" bs=1 skip=$((off + 9)) count=4 2>/dev/null)" = loob ] || continue
          cur=$(dd if="$prefs" bs=1 skip=$((off + 13)) count=1 2>/dev/null | od -An -tu1 | tr -d ' ')
          [ "$cur" = 1 ] && continue
          [ -f "$prefs.orig-pre-legacy" ] || cp "$prefs" "$prefs.orig-pre-legacy"
          printf '\001' | dd of="$prefs" bs=1 seek=$((off + 13)) count=1 conv=notrunc 2>/dev/null
        done

        # Photoshop re-creates EmbeddedWB for every dialog it opens, and the new
        # one lands on top of the dialog, so the dialog looks like it never
        # appeared. A one-shot hide only catches the instance present at
        # startup, hence a watcher that runs for the session. See pswin.c.
        ${wine-adobe}/bin/wine ${pswin}/bin/pswin.exe watch \
          OWL.MenuBar EmbeddedWB >/dev/null 2>&1 &
        watcher=$!
        trap 'kill $watcher 2>/dev/null' EXIT

        ${wine-adobe}/bin/wine "$exe" "$@"
      '';
    in {
      # NT synchronisation primitives in the kernel rather than emulated over
      # futexes in wineserver. Photoshop is heavily threaded and this is the
      # single biggest lever left for it; wineserver already looks for
      # /dev/ntsync, the module just is not autoloaded.
      boot.kernelModules = [ "ntsync" ];

      environment.systemPackages = [
        wine-adobe-run
        photoshop-setup
        photoshop
        pkgs.winetricks
      ];
    };
}
