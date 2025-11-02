{config, lib, pkgs, unstable, ... }:


{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    environmentVariables = { OLLAMA_DEBUG = "1"; };
    rocmOverrideGfx = "10.3.0";
    host = "0.0.0.0";
    acceleration = "rocm";
    openFirewall = true;
  };

  services.open-webui = {
    enable = true;
    host   = "0.0.0.0";
    package = pkgs.open-webui;
    openFirewall = true;
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
    };
  };
}
