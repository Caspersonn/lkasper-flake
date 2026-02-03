{ inputs, ... }: {
  flake.modules.nixos.monitoring = { pkgs, lib, config, ... }: {
    services.monitoring = {
      enable = true;
      root_domain = "technative.eu";

      customers = [
        {
          name = "technative";
          probesFile =
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/prometheus/customers/technative/probes/urls.yaml";
          alertRules = [
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/prometheus/customers/technative/alerts/alert-ssl_expiration.yml"
          ];
          dashboardsPath =
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/grafana/dashboards/technative";
        }
        {
          name = "improvement_it";
          probesFile =
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/prometheus/customers/improvement_it/probes/urls.yaml";
          alertRules = [
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/prometheus/customers/improvement_it/alerts/alert-ssl_expiration.yml"
          ];
          dashboardsPath =
            "${config.users.users.casper.home}/git/wearetechnative/monitoring/module/grafana/dashboards/improvementit";
        }
      ];

      alertmanager = {
        enable = true;
        configuration = {
          global.resolve_timeout = "5m";
          route = {
            receiver = "slack-notifications";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "3h";
          };
          receivers = [{
            name = "slack-notifications";
            slack_configs = [{
              send_resolved = true;
              channel = "#alerts";
              api_url_file = "/run/secrets/slack-webhook";
              text = ''
                {{ range .Alerts }}
                *{{ .Annotations.summary }}*
                {{ .Annotations.description }}
                {{ end }}
              '';
            }];
          }];
        };
      };
    };
  };
}
