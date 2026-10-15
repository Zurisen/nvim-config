-- Markdown shown styled right in the buffer: headings, bold/italic, lists,
-- checkboxes, tables, code blocks, quotes and links. The line under the cursor
-- and insert mode show the raw text, so you can still edit it.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Markdown rendering (toggle)" },
  },
  opts = {},
}
