-- Formatting on save, using the formatters Mason installs (see lsp.lua).
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
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
    -- Fall back to the language server's formatter when none is listed above.
    -- Except XML/XAML: lemminx would reformat the team's XAML on every save
    -- (including the auto-save when switching to Claude). <leader>cf still works.
    format_on_save = function(buf)
      if vim.bo[buf].filetype == "xml" then
        return
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,
  },
}
