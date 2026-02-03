{ inputs, ... }: {
  flake.modules.nixos.dev-lsp = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Language Servers
      sqls
      gopls
      nixd
      marksman
      nodePackages.bash-language-server
      lua-language-server
      nil
      rust-analyzer
      vscode-langservers-extracted
      tree-sitter

      # Formatters & Linters
      nixfmt-classic
      rustfmt
      nodePackages.prettier
      markdownlint-cli
    ];
  };
}
