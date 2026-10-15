-- Highlight TODO / FIXME / HACK / NOTE / ... in comments and list them.
return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- Also match keywords without a colon ("// TODO fix this"): many codebases
    -- write their TODOs that way.
    highlight = { pattern = [[.*<(KEYWORDS)>]] },
    search = { pattern = [[\b(KEYWORDS)\b]] },
  },
  keys = {
    { "]T", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[T", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
    { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Search TODOs" },
    { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODO list" },
  },
}
