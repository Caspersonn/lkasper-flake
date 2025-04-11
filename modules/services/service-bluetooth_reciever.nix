{ config, lib, ... }:

{
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
}
