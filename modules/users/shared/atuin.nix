{ self, ... }: {
  flake.modules.homeManager.shared-atuin = { config, lib, pkgs, unstable, ... }:
  let
    username = config.home.username;
    systemSecrets = username == "antonia";
    secretName = kind: "atuin-${username}-${kind}";
    secretPath = kind:
      if systemSecrets then "/run/agenix/${secretName kind}"
      else config.age.secrets.${secretName kind}.path;
    initialize = pkgs.writeShellScript "atuin-managed-credentials" ''
      exec ${pkgs.python3.withPackages (p: [ p.msgpack ])}/bin/python3 ${./atuin/credentials.py} \
        ${lib.escapeShellArg (secretPath "session")} \
        ${lib.escapeShellArg (secretPath "key")} \
        ${lib.escapeShellArg "${config.xdg.configHome}/atuin/config.toml"} \
        ${lib.getExe config.programs.atuin.package}
    '';
  in {
    imports = [ self.modules.homeManager.shared-age ];

    home.sessionVariables.ATUIN_CONFIG_DIR = "${config.xdg.configHome}/atuin";

    age.identityPaths = lib.mkIf (!systemSecrets) [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    age.secrets = lib.mkIf (!systemSecrets) (builtins.listToAttrs (map (kind: {
      name = secretName kind;
      value = {
        file = ../../../secrets + "/${secretName kind}.age";
        mode = "0400";
        path = "${config.xdg.stateHome}/atuin/credentials/${kind}";
      };
    }) [ "session" "key" ]));

    programs.atuin = {
      enable = true;
      package = unstable.atuin;
      enableZshIntegration = true;
      daemon.enable = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://atuin.inspiravita.com";
        common_prefix = ["ls" "cd" "z" "grep" "vi"];
        common_subcommands = ["aws-switch" "bmc" "race"];
        dialect = "uk";
        filter_mode = "host";
        history_filter = ["^export.*KEY" "^export.*TOKEN"];
        search_mode = "fuzzy";
        secrets_filter = true;
        key_path = secretPath "key";
        threads.capture = true;
        daemon.autostart = false;
        daemon.sync_frequency = 300;
        ai.enabled = false;
      };
      flags = [ "--disable-up-arrow" "--disable-ai"];
    };

    systemd.user.services.atuin-daemon = {
      Unit = {
        After = lib.optionals (!systemSecrets) [ "agenix.service" ];
        Requires = lib.optionals (!systemSecrets) [ "agenix.service" ];
        Wants = [ "atuin-threads-import.service" ];
      };
      Service = {
        ExecStartPre = [ "${initialize}" ];
        UMask = "0077";
        Environment = [ "ATUIN_CONFIG_DIR=${config.xdg.configHome}/atuin" ];
      };
    };

    systemd.user.services.atuin-threads-import = {
      Unit = {
        Description = "Import existing agent conversations into Atuin Threads";
        After = [ "atuin-daemon.service" ];
        Requires = [ "atuin-daemon.service" ];
        PartOf = [ "atuin-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe config.programs.atuin.package} threads import";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 10;
        UMask = "0077";
        Environment = [ "ATUIN_CONFIG_DIR=${config.xdg.configHome}/atuin" ];
      };
    };
  };
}
