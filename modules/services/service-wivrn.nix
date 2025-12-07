{ pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    android-tools
    bs-manager
    steam-run
    wlx-overlay-s
  ];

  services.wivrn = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    steam.importOXRRuntimes = true;
    defaultRuntime = true;
  };

  programs.envision = {
    enable = true;
    openFirewall = true;
  };

  programs.alvr = {
    enable = true;
    openFirewall = true;
  };
}
