{self, inputs, config, nixpkgs, croctalk, pkgs, ... }:
{

  # Specify the age identity path
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Specify the secret-file by infra_environment
  age.secrets.".env".file = ../secrets/.env.age;

  systemd.services.croctalk = {
    description = "Croctalk Service";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
    WorkingDirectory = "/run/agenix/";
      ExecStart = "${config.system.path}/bin/croctalk";
      Restart = "always";
      EnvironmentFile = config.age.secrets.".env".path;
      User = "root";
      Group = "root";
    };
  };
}

