{ ... }: {
  flake.modules.homeManager.shared-autojump = { ... }: {
    programs.autojump = { enable = true; };
  };
}
