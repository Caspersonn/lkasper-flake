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
          llama = {
            name = "llama.cpp (local)";
            npm = "@ai-sdk/openai-compatible";
            options = {
              baseURL = "http://127.0.0.1:8080/v1";
              apiKey = "local";
            };
            models = {
              "Huihui-gemma-4-26B-A4B-it-abliterated-TQ1_0" = { "name" = "Gemma-4-26B-A4B (local)"; };
            };
          };
          anthropic = {
            options = {
              baseURL = "http://127.0.0.1:3456";
              apiKey  = "dummy";
            };
          };
        };
        model = "llama/Huihui-gemma-4-26B-A4B-it-abliterated-TQ1_0";
      };
      themes = { };
    };
  };
}
