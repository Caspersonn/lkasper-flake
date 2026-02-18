{ unstable, ... }:
{
  programs.opencode = {
    enable = true;
    package = unstable.opencode;
    agents   = {};
    commands = {};
    settings = {
      theme = "opencode";
      autoshare = false;
      autoupdate = true;
      plugin = ["@tarquinen/opencode-dcp@latest"];
      provider = {
        amazon-bedrock = {
          options = {
            region = "eu-central-1";
            profile = "TEC-playground-student14";
          };
        };
      };
    };
    themes = {};
  };
}
