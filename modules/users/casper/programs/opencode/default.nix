{ ... }: {
  flake.modules.homeManager.casper-opencode = { unstable, ... }: {
    programs.opencode = {
      enable = true;
      package = unstable.opencode;
      agents = { };
      commands = { };
      settings = {
        theme = "opencode";
        autoshare = false;
        autoupdate = true;
        plugin = [ "@tarquinen/opencode-dcp@latest" ];
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
