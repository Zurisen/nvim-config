-- Outline sidebar: the classes/methods of the current file as a tree, from the
-- language server (roslyn for C#), highlighting where the cursor is.
return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
  keys = {
    -- Opens and moves into the outline (j/k to browse, Enter to jump);
    -- pressing it again closes it and returns to the code.
    { "<leader>m", "<cmd>AerialToggle<cr>", desc = "Methods outline (toggle)" },
  },
  opts = {
    backends = { "lsp", "treesitter", "markdown" },
    layout = {
      default_direction = "left", -- the Claude sidebar lives on the right
      min_width = 30,
    },
    show_guides = true,
    -- Moving through the outline (j/k) scrolls the code to that method
    -- straight away; Enter moves the cursor into the code.
    autojump = true,
    -- Shows classes, constructors, methods, enums... (aerial's default list
    -- leaves out fields and properties to keep the outline about methods).
  },
}
