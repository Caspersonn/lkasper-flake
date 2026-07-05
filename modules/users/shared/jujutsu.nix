
{ ... }: {
  flake.modules.homeManager.shared-jujutsu = { ... }: {
    programs.jujutsu = {
      enable = true;
    };
  };
}
