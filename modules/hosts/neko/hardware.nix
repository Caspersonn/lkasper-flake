{ lib, inputs, ... }: {
  flake.modules.nixos.neko = { config, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # Boot configuration
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    # File systems
    fileSystems."/" =
    { device = "/dev/disk/by-uuid/f2b7fc23-61fd-4bc2-849a-5d8646ebca18";
	 fsType = "ext4";
    };

    fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3B31-57A1";
	    fsType = "vfat";
	    options = [ "fmask=0077" "dmask=0077" ];
    };

    swapDevices =
	    [ { device = "/dev/disk/by-uuid/11bc44fe-e525-4ee7-be08-be15a2fe8eb4"; }
	    ];

    # Networking
    networking.useDHCP = lib.mkDefault true;

    # Platform (ARM)
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
