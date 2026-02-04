{ ... }: {
  flake.modules.homeManager.casper-autojump = { ... }: {
    programs.autojump = { enable = true; };
  };
}
