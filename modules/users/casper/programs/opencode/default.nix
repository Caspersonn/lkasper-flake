{ ... }: {
  flake.modules.homeManager.casper-opencode = { pkgs, ... }: {
    home.file = {
      ".config/opencode" = {
        source = ./config;
        recursive = true;
        executable = false;
      };
    };

    programs.opencode = {
      enable = true;
      package = pkgs.opencode;
      agents = { };
      commands = { };
      settings = {
        theme = "opencode";
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" "opencode-openai-codex-auth@latest" ];
        provider = {
          anthropic = {
            options = {
              baseURL = "https://api.anthropic.com/v1";
            };
          };
          amazon-bedrock = {
            options = {
              region = "eu-central-1";
              profile = "TEC-playground-student14";
            };
          };
        };
      };
      themes = { };
    };
  };
}
