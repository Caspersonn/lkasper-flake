{
pkgs,
home-manager,
config,
...
}: let
  colorVariants = ["dark"];
  sizeVariants = ["standard"];
  themeVariants = ["yellow"];
  tweakVariants = ["black"];
  iconVariants = ["Dark"];
  gruvbox-gtk-theme = pkgs.gruvbox-gtk-theme.override {inherit sizeVariants colorVariants themeVariants tweakVariants iconVariants;};
  # The actual theme name is "Gruvbox-Dark" based on the package contents
  gruvbox = "Gruvbox-Dark";
in {
  home.packages = [gruvbox-gtk-theme];

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";  # Changed from kvantum to gtk2 as Gruvbox doesn't include Kvantum themes
  };
  gtk = {
    enable = true;
    theme = {
      name = "${gruvbox}";  # Use the correct theme name
      package = pkgs.gruvbox-gtk-theme.override {
        colorVariants = colorVariants;
        sizeVariants = sizeVariants;
        themeVariants = themeVariants;
        tweakVariants = tweakVariants;
        iconVariants = iconVariants;
      };
    };
      #iconTheme = {
      #  package = pkgs.papirus-icon-theme;
      #  name = "Papirus-Dark";
      #};
    gtk3.extraConfig = {
      Settings = ''
      gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
      gtk-application-prefer-dark-theme=1
      '';
    };
  };

  # Set wallpaper
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = ["/home/casper/lkasper-flake/wallpapers/studio-ghibli.jpg"];
      wallpaper = [", /home/casper/lkasper-flake/wallpapers/studio-ghibli.jpg"];
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    # Remove Kvantum configuration as Gruvbox doesn't include Kvantum themes
  };
}
