{ inputs, ... }: {
  flake.modules.nixos.hardware-coolerd = { pkgs, ... }: {
    programs.coolercontrol.enable = true;

    environment.systemPackages = with pkgs; [ lm_sensors ];
  };
}
