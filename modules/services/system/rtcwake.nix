{ inputs, ... }: {
  flake.modules.nixos.rtcwake = { pkgs, ... }: {

    systemd.services.rtcwake-hibernate = {
      description = "Hibernate and wake at 7 AM next day";
      script = ''
        ${pkgs.util-linux}/bin/rtcwake -m disk -l -t $(${pkgs.coreutils}/bin/date +%s -d 'today 07:00')
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.timers.rtcwake-hibernate = {
      description = "Hibernate at 00:00 AM daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 00:05:00";
        Persistent = true;
      };
    };

  };
}
