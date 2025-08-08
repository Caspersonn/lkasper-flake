{config, ...}:

{
    programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
            auto_sync = true;
            sync_frequency = "5m";
            sync_address = "https://api.atuin.sh";
            search_mode = "prefix";
        };
    };
}
