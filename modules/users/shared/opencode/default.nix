{ ... }: {
  flake.modules.homeManager.shared-opencode = { pkgs, config, unstable, ... }: {
    home.file = {
      ".config/opencode" = {
        source = ./config;
        recursive = true;
        executable = false;
      };
    };

    programs.opencode = {
      enable = true;
      package = unstable.opencode;
      agents = { };
      commands = { };
      tui = {
      };
      settings = {
        theme = "opencode";
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" "opencode-openai-codex-auth@latest" "opencode-with-claude" ];
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
  };
}
