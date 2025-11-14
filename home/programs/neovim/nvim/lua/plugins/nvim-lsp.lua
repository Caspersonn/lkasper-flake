local nilcmd = vim.fn.expand('$HOME/.nix-profile/bin/nil')
return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      auto_install = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config('elixirls', {
        cmd = { "elixir-ls" },
        capabilities = capabilities,
      })
      vim.lsp.enable('elixirls')

      vim.lsp.config('ts_ls',{
        capabilities = capabilities,
      })
      vim.lsp.enable('ts_ls')

      vim.lsp.config('html',{
        capabilities = capabilities,
      })
      vim.lsp.enable('html')

      vim.lsp.config('jsonls',{
        capabilities = capabilities,
      })
      vim.lsp.enable('jsonls')

      vim.lsp.config('pyright',{
        capabilities = capabilities,
      })
      vim.lsp.enable('pyright')

      vim.lsp.config('lua_ls',{
        settings = {
          Lua = {
            diagnostics = {
              globals = {
                'vim',
                'pandoc',
                'require',
                'FORMAT'
              },
            },
          }
        },
        capabilities = capabilities,
      })
      vim.lsp.enable('lua_ls')

      vim.lsp.config('nil_ls',{
        capabilities = capabilities,
        cmd = { nilcmd },
        filetypes = { 'nix' },
        single_file_support = true,
        flake = {
          -- calls `nix flake archive` to put a flake and its output to store
          autoArchive = true,
        },
      })
      vim.lsp.enable('nil_ls')

      vim.lsp.config('marksman',{
        capabilities = capabilities,
        cmd = {
          "sh",
          "-c",
          "test -x /run/current-system/sw/bin/marksman && { /run/current-system/sw/bin/marksman server; } || { marksman server; }",
        },
        handlers = {
          ["textDocument/publishDiagnostics"] = function() end,
        },
      })
      vim.lsp.enable('marksman')

      vim.lsp.config('terraformls',{
        capabilities = capabilities,
      })
      vim.lsp.enable('terraformls')

      vim.lsp.config('crystalline',{
        capabilities = capabilities,
      })
      vim.lsp.enable('crystalline')

      vim.lsp.config('bashls',{
        capabilities = capabilities,
      })
      vim.lsp.enable('bashls')

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
