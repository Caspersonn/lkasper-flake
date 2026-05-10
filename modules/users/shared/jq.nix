{ ... }: {
  flake.modules.homeManager.shared-jq = { ... }: {
    programs.jq = { enable = true; };
  };
}
