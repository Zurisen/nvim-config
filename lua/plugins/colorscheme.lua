return {
  "Mofiqul/dracula.nvim", -- matches the Dracula theme from VS Code
  lazy = false,
  priority = 1000, -- load before every other plugin so highlights are right
  opts = {
    italic_comment = true,
  },
  config = function(_, opts)
    require("dracula").setup(opts)
    vim.cmd.colorscheme("dracula")
  end,
}
