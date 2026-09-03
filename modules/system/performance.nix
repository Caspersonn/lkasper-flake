{ inputs, ... }: {
  flake.modules.nixos.performance = { config, pkgs, lib, ... }: {
    # ---------------------------------------------------------------
    # zram: compressed swap in RAM.
    #
    # This machine's disk swap sits on LUKS-encrypted NVMe, so every
    # page fault costs a disk read *plus* an AES decrypt. zram keeps
    # swapped pages in RAM instead, compressed with zstd (~3:1 on
    # browser heaps), which turns a millisecond-scale disk stall into
    # a microsecond-scale decompress.
    #
    # The NixOS module gives zram priority 5; the disk swap sits at -2,
    # so zram fills first and disk swap becomes cold overflow only.
    # ---------------------------------------------------------------
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 180;

      "vm.page-cluster" = 0;

      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;

      "vm.vfs_cache_pressure" = 50;

      "vm.dirty_bytes" = 268435456;
      "vm.dirty_background_bytes" = 134217728;
    };

    services.earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 10;
      extraArgs = [
        "--avoid"
        "^(Hyprland|systemd|sshd|waybar|pipewire|wireplumber)$"
        "--prefer"
        "^(Isolated Web Co|Web Content|chrome|electron|QtWebEngineProc)$"
      ];
    };
  };
}
