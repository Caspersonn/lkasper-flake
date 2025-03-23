{config, lib, pkgs, unstable, ... }:


{
  services.ollama = {
    enable = true;
    package = unstable.ollama-rocm;
    environmentVariables = { OLLAMA_DEBUG = "1"; };
    rocmOverrideGfx = "10.3.1";
    host = "0.0.0.0";
    acceleration = "rocm";
    loadModels = [ "codellama:13b" ];
  };

  services.open-webui = {
    enable = true;
    host   = "0.0.0.0";
  };
}
