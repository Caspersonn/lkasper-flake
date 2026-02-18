{ ... }: {
  programs.eww = {
    enable = true;
    enableZshIntegration = true;
    #configDir = ./bar;
  };
  #home.file = {
  #  ".config/eww" = {
  #    source = ./bar;
  #    recursive = true;
  #    executable = true;
  #  };
  #};
}
