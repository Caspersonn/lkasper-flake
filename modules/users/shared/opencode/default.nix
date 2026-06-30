{ inputs, ... }: {
  flake.modules.homeManager.shared-opencode = { pkgs, config, unstable, ... }: {
    programs.opencode = {
      enable = true;
      package = unstable.opencode;
      agents = { };
      commands = { };
      tui = {
        theme = "opencode";
      };
      settings = {
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" "opencode-openai-codex-auth@latest" config.services.meridian.opencode.pluginPath ];
        provider = {
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
    imports = [
      inputs.meridian.homeManagerModules.default
    ];

    xdg.configFile."meridian/sdk-features.json".text = builtins.toJSON {
      opencode = {
        clientSystemPrompt = false;
        codeSystemPrompt = true;
      };
    };

    services.meridian = {
      enable = true;

      settings = {
        port = 3456;
        host = "127.0.0.1";
        passthrough = true;
        defaultAgent = "opencode";
      };

      environment = {
        MERIDIAN_CLAUDE_PATH = "/run/current-system/sw/bin/claude";
        MERIDIAN_DEBUG = "1";
      };
    };
  };
}
