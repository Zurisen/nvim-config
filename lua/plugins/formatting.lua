-- Formatting on demand (<leader>cf), using the formatters Mason installs (see
-- lsp.lua). Never on save: reformatting whole files adds unrelated git changes.
return {
  "stevearc/conform.nvim",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      cs = { "csharpier" },
      python = { "ruff_organize_imports", "ruff_format" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      json = { "prettierd" },
      lua = { "stylua" },
    },
  },
}
