{ lib, inputs, ... }: {
  flake.modules.nixos.server-casper = { config, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    # Boot configuration
    boot.initrd.availableKernelModules = [ "xhci_pci" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    # File systems
    fileSystems."/" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };

    # No swap devices
    swapDevices = [ ];

    # Networking
    networking.useDHCP = lib.mkDefault true;

    # Platform (ARM)
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  };
}
