{ ... }: {
  programs.eww = {
    enable = true;
    enableZshIntegration = true;
  };
  home.file = {
    ".config/eww" = {
      source = ./empty_workspace;
      recursive = true;
      executable = true;
    };
  };
}
