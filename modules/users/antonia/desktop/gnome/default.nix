{ inputs, ... }: {
  flake.modules.homeManager.gnome = { pkgs, lib, ... }:
    let self-pkgs = inputs.self.packages.${pkgs.system};
    in {
      home.packages = with pkgs; [
        gnomeExtensions.dash-to-dock
        gnomeExtensions.just-perfection
        gnomeExtensions.user-themes
        gnome-tweaks
        inter
        jetbrains-mono
      ];

      gtk = {
        enable = true;
        theme = {
          name = "WhiteSur-Dark";
          package = self-pkgs.whitesur-gtk-theme;
        };
        iconTheme = {
          name = "WhiteSur-dark";
          package = self-pkgs.whitesur-icon-theme;
        };
        cursorTheme = {
          name = "WhiteSur-cursors";
          size = 24;
          package = self-pkgs.whitesur-cursors;
        };
        gtk3.extraConfig = { gtk-application-prefer-dark-theme = true; };
        gtk4.extraConfig = { gtk-application-prefer-dark-theme = true; };
      };

      home.pointerCursor = {
        name = "WhiteSur-cursors";
        size = 24;
        package = self-pkgs.whitesur-cursors;
        gtk.enable = true;
        x11.enable = true;
      };

      fonts.fontconfig.enable = true;

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "WhiteSur-Dark";
          icon-theme = "WhiteSur-dark";
          cursor-theme = "WhiteSur-cursors";
          cursor-size = 24;
          font-name = "Inter 11";
          document-font-name = "Inter 11";
          monospace-font-name = "JetBrains Mono 10";
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          enable-animations = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "close,minimize,maximize:";
          titlebar-font = "Inter Bold 11";
          theme = "WhiteSur-Dark";
        };
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            "dash-to-dock@micxgx.gmail.com"
            "just-perfection-desktop@just-perfection"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
          ];
        };
        "org/gnome/shell/extensions/user-theme" = { name = "WhiteSur-Dark"; };
        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = "BOTTOM";
          dock-fixed = false;
          autohide = true;
          intellihide = true;
          intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
          dash-max-icon-size = 48;
          icon-size-fixed = true;
          show-apps-at-top = false;
          show-mounts = false;
          show-trash = false;
          extend-height = false;
          transparency-mode = "DYNAMIC";
          background-opacity = 0.8;
          customize-alphas = true;
          min-alpha = 0.4;
          max-alpha = 0.8;
          running-indicator-style = "DOTS";
          apply-custom-theme = true;
        };
        "org/gnome/shell/extensions/just-perfection" = {
          panel = true;
          panel-in-overview = true;
          activities-button = false;
          app-menu = false;
          clock-menu-position = 1;
          window-demands-attention-focus = true;
          startup-status = 0;
          animation = 3;
        };
        "org/gnome/desktop/background" = {
          picture-uri =
            "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-l.jxl";
          picture-uri-dark =
            "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-d.jxl";
          picture-options = "zoom";
        };
        "org/gnome/mutter" = {
          dynamic-workspaces = true;
          edge-tiling = true;
          workspaces-only-on-primary = true;
          experimental-features = [ "scale-monitor-framebuffer" ];
        };
        "org/gnome/desktop/peripherals/mouse" = { accel-profile = "flat"; };

        "org/gnome/shell/app-switcher" = { current-workspace-only = false; };
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>w" ];
          toggle-maximized = [ "<Super>m" ];
          minimize = [ "<Super>h" ];
          switch-applications = [ "<Super>Tab" ];
          switch-windows = [ "<Alt>Tab" ];
        };
      };

      home.activation.whitesur-themes =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p $HOME/.local/share/themes
          $DRY_RUN_CMD mkdir -p $HOME/.local/share/icons
          $DRY_RUN_CMD ln -sfn ${self-pkgs.whitesur-gtk-theme}/share/themes/WhiteSur-Dark $HOME/.local/share/themes/WhiteSur-Dark
          $DRY_RUN_CMD ln -sfn ${self-pkgs.whitesur-icon-theme}/share/icons/WhiteSur-dark $HOME/.local/share/icons/WhiteSur-dark
          $DRY_RUN_CMD ln -sfn ${self-pkgs.whitesur-cursors}/share/icons/WhiteSur-cursors $HOME/.local/share/icons/WhiteSur-cursors
        '';
    };
}
