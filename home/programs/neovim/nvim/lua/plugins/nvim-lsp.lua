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

      local lspconfig = require("lspconfig")
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })

      lspconfig.html.setup({
        capabilities = capabilities,
      })

      lspconfig.jsonls.setup({
        capabilities = capabilities,
      })

      lspconfig.pyright.setup({
        capabilities = capabilities,
      })

      lspconfig.lua_ls.setup({
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

      lspconfig.nil_ls.setup({
        capabilities = capabilities,
        cmd = { nilcmd },
        filetypes = { 'nix' },
        single_file_support = true,
        flake = {
          -- calls `nix flake archive` to put a flake and its output to store
          autoArchive = true,
        },
      })
      lspconfig.marksman.setup({
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

      lspconfig.terraformls.setup({
        capabilities = capabilities,
      })

      lspconfig.crystalline.setup({
        capabilities = capabilities,
      })

      lspconfig.bashls.setup({
        capabilities = capabilities,
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
