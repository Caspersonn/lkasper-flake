{ inputs, ... }: {
  flake.modules.nixos.dev-lsp = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Language Servers
      sqls
      gopls
      nixd
      marksman
      lua-language-server
      nil
      rust-analyzer
      vscode-langservers-extracted
      tree-sitter

      # Formatters & Linters
      nixfmt
      rustfmt
      markdownlint-cli
    ];
  };
}
