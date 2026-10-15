-- Fuzzy finder for files, text (ripgrep), buffers, help, LSP symbols...
return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-ui-select.nvim", -- use Telescope for code-action menus etc.
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>sf", "<cmd>Telescope find_files<CR>", desc = "Search files" },
    { "<leader>sg", "<cmd>Telescope live_grep<CR>", desc = "Search by grep" },
    { "<leader>sw", "<cmd>Telescope grep_string<CR>", desc = "Search word under cursor" },
    { "<leader>sd", "<cmd>Telescope diagnostics<CR>", desc = "Search diagnostics" },
    { "<leader>sh", "<cmd>Telescope help_tags<CR>", desc = "Search help" },
    { "<leader>sk", "<cmd>Telescope keymaps<CR>", desc = "Search keymaps" },
    { "<leader>sr", "<cmd>Telescope resume<CR>", desc = "Resume last search" },
    { "<leader>s.", "<cmd>Telescope oldfiles<CR>", desc = "Search recent files" },
    { "<leader><leader>", "<cmd>Telescope buffers<CR>", desc = "Find open buffers" },
    { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in current buffer" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        -- One Esc closes the picker (like VS Code) instead of entering normal mode.
        mappings = { i = { ["<Esc>"] = require("telescope.actions").close } },
        -- Open the chosen file in the code window, even when the search was
        -- started from Claude, the git window or a terminal.
        get_selection_window = function()
          return require("config.navigation").code_win_for_open()
        end,
      },
      pickers = {
        find_files = {
          -- Also git-ignored and hidden files (notes in .claude/docs, docs/,
          -- .github/...), minus build output and binaries.
          find_command = {
            "rg", "--files", "--hidden", "--no-ignore",
            "-g", "!.git", "-g", "!.vs", "-g", "!bin", "-g", "!obj",
            "-g", "!node_modules", "-g", "!__pycache__", "-g", "!.venv", "-g", "!venv",
            "-g", "!*.{dll,pdb,exe,baml,cache,pyc}",
          },
        },
      },
      extensions = {
        ["ui-select"] = { require("telescope.themes").get_dropdown() },
      },
    })
    telescope.load_extension("ui-select")
  end,
}
