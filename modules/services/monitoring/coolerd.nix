{ inputs, ... }: {
  flake.modules.nixos.coolerd = { pkgs, ... }: {
    programs.coolercontrol.enable = true;

    environment.systemPackages = with pkgs; [ lm_sensors ];
  };
}
