{ inputs, ... }: {
  flake.modules.nixos.bluetooth-receiver = { config, pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          DiscoverableTimeout = "0";
          Enable = "Source,Sink,Media,Socket";
          AlwaysPairable = true;
        };
      };
    };
  };
}
