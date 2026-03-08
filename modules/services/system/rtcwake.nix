{ inputs, ... }: {
  flake.modules.nixos.rtcwake = { pkgs, ... }: {

    systemd.services.rtcwake-hibernate = {
      description = "Hibernate and wake at 7 AM";
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.util-linux}/bin/rtcwake -m disk -l -t $(${pkgs.coreutils}/bin/date +%%s -d 'tomorrow 07:00')";
      };
    };

    systemd.timers.rtcwake-hibernate = {
      description = "Hibernate at 10 PM daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 22:00:00";
        Persistent = true;
      };
    };

  };
}
