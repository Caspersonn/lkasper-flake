{ inputs, ... }: {
  flake.modules.nixos.llama-cpp = { config, lib, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      llama-cpp
    ];

    services.llama-cpp = {
      enable = true;
      # Vulkan build so layers can run on the AMD (Phoenix) iGPU via RADV.
      package = pkgs.llama-cpp.override { vulkanSupport = true; };
      host = "127.0.0.1";
      modelsDir = "/var/lib/llama-cpp/models";
      extraFlags = [
        "-fa" "on"
        "-ngl" "99"
        "--n-cpu-moe" "20"
        "-np" "1"
        "-c" "16384"
      ];
    };

    systemd.services.llama-cpp = {
      serviceConfig = {
        SupplementaryGroups = [ "render" "video" ];
        MemoryDenyWriteExecute = lib.mkForce false;
      };
      environment = {
        VK_ICD_FILENAMES =
          "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
        MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";
      };
    };
  };
}
