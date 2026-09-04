{ ... }: {
  flake.modules.homeManager.shared-atuin = { ... }: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = "https://atuin.inspiravita.com";
        common_prefix = ["ls" "cd" "z" "grep" "vi"];
        common_subcommands = ["aws-switch" "bmc" "race"];
        dialect = "uk";
        filter_mode = "host";
        history_filter = ["^export.*KEY" "^export.*TOKEN"];
        search_mode = "fuzzy";
        secrets_filter = true;
      };
      flags = [ "--disable-up-arrow" "--disable-ai"];

      settings = {
        ai = {
          enabled = false;
        };
      };
    };
  };
}
