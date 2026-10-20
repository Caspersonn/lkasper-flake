{ inputs, ... }: {
  flake.modules.homeManager.shared-meridian = { lib, pkgs, config, unstable, ... }: {
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
        MERIDIAN_CLAUDE_PATH = lib.getExe unstable.claude-code;
        MERIDIAN_DEBUG = "1";
      };
    };
  };
}
