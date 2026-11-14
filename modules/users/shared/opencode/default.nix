{ inputs, ... }: {
  flake.modules.homeManager.shared-opencode = { pkgs, config, unstable, ... }: {
    home.file = {
      ".config/opencode/" = {
        source = ./config;
        recursive = true;
      };
    };
    programs.opencode = {
      enable = true;
      package = inputs.opencode-v2.packages."${pkgs.system}".default;
      enableMcpIntegration = true;

      agents = ./agents;
      commands = ./commands;
      context = ./AGENTS.md;
      tui = {
        theme = "opencode";
      };
      settings = {
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" config.services.meridian.opencode.pluginPath "opencode-tps-meter@latest" ];

        model = "opencode-go/deepseek-v4.1-flash";
        small_model = "opencode-go/deepseek-v4.1-flash";

        agent = {
          explore = {
            model = "opencode-go/deepseek-v4.1-flash";
          };
        };

        mcp = {
          linny = {
            enabled = true;
            type = "remote";
            url = "http://127.0.0.1:8765/mcp";
            headers = {
              Authorization = "Bearer {file:/tmp/linny-mcp-tokens}";
            };
          };
          jira-technative = {
            type = "local";
            command = ["${pkgs.uv}/bin/uvx" "mcp-atlassian"];
            environment = {
              JIRA_URL = "https://technative.atlassian.net";
              JIRA_USERNAME = "luca.kasper@technative.eu";
              JIRA_API_TOKEN = "{file:/run/agenix/jira-api-token}";
            };
            enabled = true;
          };
          jira-postnl = {
            type = "local";
            command = ["${pkgs.uv}/bin/uvx" "mcp-atlassian"];
            environment = {
              JIRA_URL = "https://postnl.atlassian.net";
              JIRA_USERNAME = "luca.kasper@postnl.nl";
              JIRA_API_TOKEN = "{file:/run/agenix/jira-api-token-postnl}";
            };
            enabled = true;
          };
        };

        provider = {
          opencode-go = {
            options = {
              apiKey = "{file:/tmp/opencode-go-api-key}";
            };
          };
          llama = {
            name = "llama.cpp";
            npm = "@ai-sdk/openai-compatible";
            options = {
              baseURL = "https://ollama.ainative.eu/v1";
              apiKey = "local";
            };
            models = {
              "laguna-xs-2.1:latest" = {
                name = "laguna-xs-2.1:latest";
                limit = {
                  context = 32768;
                  output = 16384;
                };
                options = {
                  reasoningEffort = "none";
                };
              };
              "qwen3.5-fast-8k:latest" = {
                name = "qwen3.5-fast-8k:latest";
                limit = {
                  context = 8192;
                  output = 2048;
                };
                options = {
                  reasoningEffort = "none";
                };
              };
              "qwen3.5:4b" = {
                name = "qwen3.5:4b";
                limit = {
                  context = 262144;
                  output = 16384;
                };
              };
            };
          };
          anthropic = {
            options = {
              baseURL = "http://127.0.0.1:3456";
              apiKey  = "dummy";
            };
          };
        };
      };
      themes = { };
    };
  };
}
