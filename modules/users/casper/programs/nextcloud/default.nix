{ ... }: {
  flake.modules.homeManager.casper-nextcloud = { config, pkgs, unstable, ... }: {

    home.packages = with pkgs; [
      nextcloud-client
    ];

    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secrets = {
        nextcloud-casper-netrc = {
          file = ../../../../../secrets/nextcloud-casper-netrc.age;
          path = "${config.home.homeDirectory}/.netrc";
          symlink = true;
        };
      };
    };

    systemd.user = {
      services.nextcloud-autosync = {
        Unit = {
          Description = "Auto sync Nextcloud";
          After = "network-online.target";
        };
        Service = {
          Type = "simple";
          ExecStart= "${pkgs.nextcloud-client}/bin/nextcloudcmd -h -n --path /Documents /home/casper/Documents https://nextcloud.inspiravita.com";
          TimeoutStopSec = "300";
          KillMode = "process";
          KillSignal = "SIGINT";
        };
        Install.WantedBy = ["multi-user.target"];
      };
      timers.nextcloud-autosync = {
        Unit.Description = "Automatic sync files with Nextcloud when booted up after 5 minutes then rerun every 15 minutes";
        Timer.OnBootSec = "5min";
        Timer.OnUnitActiveSec = "15min";
        Install.WantedBy = ["multi-user.target" "timers.target"];
      };
      startServices = true;
    };
  };
}
