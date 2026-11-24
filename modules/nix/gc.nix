{ inputs, ... }:
{
  # Daily disk cleanup: Nix GC that keeps a week of rollbacks, store
  # optimisation, and pruning of dangling Docker images only.
  flake.modules.nixos.nix-gc =
    { config, lib, ... }:
    let
      docker = config.virtualisation.docker;
    in
    {
      nix.gc = {
        automatic = true;
        dates = "daily";
        # Not `-d`: generations from the last 7 days stay available for rollback.
        options = "--delete-older-than 7d";
        persistent = true;
        randomizedDelaySec = "45min";
      };

      nix.optimise = {
        automatic = true;
        # Well before the 03:30 kaito state backup.
        dates = [ "01:30" ];
        persistent = true;
      };

      # Deliberately not `virtualisation.docker.autoPrune`: that runs
      # `docker system prune`, which also removes unused networks (e.g. the
      # oneshot-created solidtime-net). Only untagged images older than 7 days
      # are removed here; never containers, volumes, networks or tagged images.
      systemd.services.docker-image-prune = lib.mkIf docker.enable {
        description = "Prune dangling Docker images older than 7 days";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${docker.package}/bin/docker image prune --force --filter until=168h";
        };
      };

      systemd.timers.docker-image-prune = lib.mkIf docker.enable {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
}
