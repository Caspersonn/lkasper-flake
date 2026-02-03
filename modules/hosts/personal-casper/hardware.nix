{ lib, inputs, ... }: {
  flake.modules.nixos.personal-casper = { config, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # Boot configuration
    boot.initrd.availableKernelModules =
      [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    # File systems
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/bd0012e6-642e-4ba6-8591-0c6e7c42ec29";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/4C60-7E8D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    # LUKS
    boot.initrd.luks.devices."luks-a54f93ca-a783-42ac-97db-bb2e8da25559".device =
      "/dev/disk/by-uuid/a54f93ca-a783-42ac-97db-bb2e8da25559";

    # Swap
    swapDevices =
      [{ device = "/dev/disk/by-uuid/409543df-c3f3-436d-9d26-6fb3f48d5be8"; }];

    # Networking
    networking.useDHCP = lib.mkDefault true;

    # Platform and CPU
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
