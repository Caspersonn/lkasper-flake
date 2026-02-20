{ inputs, ... }: {
  flake.modules.homeManager.gnome = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      whitesur-icon-theme
      gnomeExtensions.dash-to-dock
      gnomeExtensions.just-perfection
      gnomeExtensions.user-themes
      gnome-tweaks
      inter
    ];
    gtk = {
      enable = true;
      theme = {
        name = "WhiteSur-Dark";
        package = inputs.self.packages.${pkgs.system}.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur-dark";
        package = inputs.self.packages.${pkgs.system}.whitesur-icon-theme;
      };
      cursorTheme = {
        name = "WhiteSur-cursors";
        size = 24;
      };
      gtk3.extraConfig = { gtk-application-prefer-dark-theme = true; };
      gtk4.extraConfig = { gtk-application-prefer-dark-theme = true; };
    };
    fonts.fontconfig.enable = true;
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "WhiteSur-Dark";
        icon-theme = "WhiteSur-dark";
        cursor-theme = "WhiteSur-cursors";
        font-name = "Inter 11";
        document-font-name = "Inter 11";
        monospace-font-name = "JetBrains Mono 10";
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close,minimize,maximize:";
        titlebar-font = "Inter Bold 11";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "dash-to-dock@micxgx.gmail.com"
          "just-perfection-desktop@just-perfection"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
      };
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
        animation = 2;
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
      };
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
        $DRY_RUN_CMD mkdir -p $HOME/.themes
        $DRY_RUN_CMD mkdir -p $HOME/.icons
        $DRY_RUN_CMD ln -sf ${pkgs.whitesur-gtk-theme}/share/themes/* $HOME/.themes/
        $DRY_RUN_CMD ln -sf ${pkgs.whitesur-icon-theme}/share/icons/* $HOME/.icons/
      '';
  };
}
