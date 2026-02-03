{ lib, inputs, ... }: {
  flake.modules.nixos.technative-casper = { config, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # Boot configuration
    boot.initrd.availableKernelModules =
      [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" "i2c-dev" ];
    boot.extraModulePackages = [ ];
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # File systems
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/4c322854-c1a1-42cb-a3d7-321e963b3d24";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/0342-F7A8";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    # LUKS
    boot.initrd.luks.devices."luks-e75d3f62-c634-4748-8709-64b1956e87ae".device =
      "/dev/disk/by-uuid/e75d3f62-c634-4748-8709-64b1956e87ae";

    # Swap
    swapDevices =
      [{ device = "/dev/disk/by-uuid/0d7326b9-20b5-4e34-895a-5daf83a75f9e"; }];

    # Networking
    networking.useDHCP = lib.mkDefault true;

    # Platform and CPU
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
