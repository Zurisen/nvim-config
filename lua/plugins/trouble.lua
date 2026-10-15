-- Trouble: a clickable panel for errors/warnings, references, quickfix and
-- TODOs. Like Visual Studio's Error List: it shows the diagnostics of open
-- files plus build errors from Ctrl+Shift+B (which cover the whole solution).
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    focus = true, -- move into the panel when it opens
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Errors & warnings (all)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Errors & warnings (this file)" },
    { "<leader>xr", "<cmd>Trouble lsp_references toggle<cr>", desc = "References of symbol under cursor" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
  },
}
