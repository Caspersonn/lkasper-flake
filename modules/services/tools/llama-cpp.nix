{ inputs, ... }: {
  flake.modules.nixos.llama-cpp = { config, lib, pkgs, ... }: {
    services.llama-cpp = {
      enable = true;
      # Vulkan build so layers can run on the AMD (Phoenix) iGPU via RADV.
      package = pkgs.llama-cpp.override { vulkanSupport = true; };
      host = "127.0.0.1";
      modelsDir = "/var/lib/llama-cpp/models";
      extraFlags = [
        # Model in use: Qwen3-30B-A3B-Instruct-2507 Q4_K_M -- a standard qwen3moe
        # (128 experts, 8 active, ~3B active params/token) with a K-quant that
        # RADV/Vulkan HAS kernels for. So the iGPU is finally usable here.
        #
        # iGPU-MoE split: the full ~18.6GB won't fit in the ~13GB of addressable
        # GTT, so we DON'T offload the whole model. Instead put the small
        # non-expert tensors (attention, norms, KV cache) on the iGPU, and keep
        # the bulky expert FFNs on CPU (REPACK/AVX2) -- only ~3B are active per
        # token, so CPU handles them cheaply.
        # NOTE: do NOT add --no-mmap here. It forces all 18.6GB into committed
        # physical RAM; RADV then can't pin its GTT command buffer -> crash
        # "radv/amdgpu: Not enough memory for command submission" / ErrorDeviceLost.
        # With mmap (default) the CPU expert weights stay file-backed/evictable,
        # leaving physical RAM free for the GPU to pin. Only ~8/128 experts are
        # touched per token, so paging is a non-issue for this MoE.
        "-fa" "on"           # flash attention: shrinks KV cache + compute buffers
                             # on the iGPU, giving headroom so the alloc fits.
        "-ngl" "99"          # all layers' non-expert tensors + KV -> iGPU (Vulkan)
        "--n-cpu-moe" "20"   # keep only the FIRST 20 layers' experts on CPU; push
                             # the other 28 (~360MB/layer ≈ 10GB) onto the iGPU.
                             # tg is bandwidth-bound and the 6 CPU cores saturate
                             # only ~half the LPDDR5 bus, so more experts on the
                             # iGPU ≈ more effective bandwidth ≈ higher t/s.
                             # TUNING LEVER: GPU had ~13.6GB free at n-cpu-moe 99.
                             # If this loads with room to spare, LOWER toward ~14
                             # for more speed; RAISE it if the GPU alloc OOMs.
        "-np" "1"            # single-user assistant: one slot gets the full context
        "-c" "16384"         # context cap; keeps the KV cache modest
      ];
    };

    # The upstream module runs this service heavily sandboxed as a DynamicUser.
    # Grant the carve-outs Vulkan/RADV needs to reach the GPU.
    systemd.services.llama-cpp = {
      serviceConfig = {
        SupplementaryGroups = [ "render" "video" ];
        # RADV compiles shaders at runtime; strict W^X memory would break it.
        MemoryDenyWriteExecute = lib.mkForce false;
      };
      environment = {
        # Point the Vulkan loader at the system RADV ICD (sandbox-safe, read-only).
        VK_ICD_FILENAMES =
          "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
        # $HOME is unset + FS is read-only under the sandbox, so RADV can't write
        # its shader cache. Redirect it to the service's writable CacheDirectory
        # so shaders persist across restarts instead of recompiling every load.
        MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";
      };
    };
  };
}
