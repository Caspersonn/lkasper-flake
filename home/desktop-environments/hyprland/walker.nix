{inputs, ...}:
{
  programs.elephant = {
    enable = true;
    debug = false;

    # Select specific providers
    providers = [
      #"files"
      "desktopapplications"
      "calc"
      "runner"
      "clipboard"
      "symbols"
      "websearch"
      "menus"
      "providerlist"
    ];

    # Custom elephant configuration
    settings = {
      providers = {
        files = {
          min_score = 50;
          icon = "folder";
        };
        desktopapplications = {
          launch_prefix = "uwsm app --";
          min_score = 60;
        };
        calc = {
          icon = "accessories-calculator";
        };
      };
    };
  };
  programs.walker = {
    enable = true;
    runAsService = true;
  };
}
