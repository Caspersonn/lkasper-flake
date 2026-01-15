{pkgs, lib, ...}:
{

  services.monitoring = {
    enable = true;

    root_domain = "technative.eu";

    customers = [
      {
        name = "technative";
        probesFile = /home/casper/git/wearetechnative/monitoring/module/prometheus/customers/technative/probes/urls.yaml;
        alertRules = [
          /home/casper/git/wearetechnative/monitoring/module/prometheus/customers/technative/alerts/alert-ssl_expiration.yml
        ];
        dashboardsPath = /home/casper/git/wearetechnative/monitoring/module/grafana/dashboards/technative;  # Optional: Grafana dashboards
      }
      {
        name = "improvement_it";
        probesFile = /home/casper/git/wearetechnative/monitoring/module/prometheus/customers/improvement_it/probes/urls.yaml;
        alertRules = [
          /home/casper/git/wearetechnative/monitoring/module/prometheus/customers/improvement_it/alerts/alert-ssl_expiration.yml
        ];
        dashboardsPath = /home/casper/git/wearetechnative/monitoring/module/grafana/dashboards/improvementit;
        #blackboxModule = "http_2xx";
        #refreshInterval = "5m";
      }
    ];

    # Optional: Configure Alertmanager for notifications
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

        receivers = [
          {
            name = "slack-notifications";
            slack_configs = [
              {
                send_resolved = true;
                channel = "#alerts";
                api_url_file = "/run/secrets/slack-webhook";
                text = ''
                  {{ range .Alerts }}
                  *{{ .Annotations.summary }}*
                  {{ .Annotations.description }}
                  {{ end }}
                '';
              }
            ];
          }
        ];
      };
    };
  };

  # Example: Configure secrets with agenix (if using agenix)
  # age.secrets.slack-webhook = {
  #   file = ./secrets/slack-webhook.age;
  #   path = "/run/secrets/slack-webhook";
  #   owner = "alertmanager";
  #   group = "alertmanager";
  #   mode = "0400";
  # };
}
