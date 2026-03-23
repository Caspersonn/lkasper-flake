{ ... }: {
  flake.modules.homeManager.casper-opencode = { pkgs, ... }: {
    programs.opencode = {
      enable = true;
      package = pkgs.opencode;
      agents = { };
      commands = { };
      settings = {
        theme = "opencode";
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" "@code-yeongyu/oh-my-openagent@latest" ];
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
