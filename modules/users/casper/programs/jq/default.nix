{ ... }: {
  flake.modules.homeManager.casper-jq = { ... }: {
    programs.jq = { enable = true; };
  };
}
