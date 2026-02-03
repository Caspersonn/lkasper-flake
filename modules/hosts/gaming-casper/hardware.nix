{ lib, inputs, ... }: {
  flake.modules.nixos.gaming-casper = { config, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # Boot configuration
    boot.initrd.availableKernelModules =
      [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.kernelModules =
      [ "kvm-amd" "coretemp" "nct6687" "zenpower" "i2c-dev" ];
    boot.kernelPackages = pkgs.linuxPackages_6_12;
    boot.extraModulePackages =
      [ pkgs.linuxKernel.packages.linux_6_12.nct6687d ];
    boot.supportedFilesystems = [ "ntfs" ];

    # File systems
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/28f48a79-46a9-4530-a584-1666b40b7c5f";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/332C-4D51";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    # Other drives
    fileSystems."/mnt/Second Drive" = {
      device = "/dev/disk/by-uuid/966c43da-65ac-479a-9e16-14ebd7669c3a";
      fsType = "ext4";
    };

    # Swap
    swapDevices =
      [{ device = "/dev/disk/by-uuid/7d222987-c0ce-4caa-a8de-21a7447a0d85"; }];

    # Networking
    networking.useDHCP = lib.mkDefault true;

    # Platform and CPU
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
