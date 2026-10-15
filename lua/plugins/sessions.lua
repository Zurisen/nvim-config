-- Session restore: reopen the files and splits you had, per project folder.
-- Saved automatically on exit; restored automatically when you start `nvim`
-- (or `nvim .`) in the same folder. Starting with a file argument skips it.
local function is_sidebar(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype
  return vim.bo[buf].buftype == "terminal" -- Claude, lazygit, terminals
    or ft == "neo-tree" or ft == "aerial" or ft:match("^dapui") or ft == "dap-repl" or ft:match("^neotest")
end

return {
  "rmagatti/auto-session",
  lazy = false, -- must run at startup to restore
  keys = {
    { "<leader>ws", "<cmd>AutoSession search<cr>", desc = "Find session" },
    { "<leader>wr", "<cmd>AutoSession restore<cr>", desc = "Restore session for this folder" },
    { "<leader>wd", "<cmd>AutoSession delete<cr>", desc = "Delete session for this folder" },
  },
  init = function()
    -- No terminal buffers and no empty windows in sessions.
    vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
  end,
  opts = {
    -- Never create sessions for broad folders.
    suppressed_dirs = { "~/", "~/Downloads", "~/Desktop", "C:/", "C:\\" },
    -- Close sidebars/panels before saving so they don't come back as blank
    -- windows (the Claude process keeps running until Neovim exits).
    pre_save_cmds = {
      function()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if #vim.api.nvim_tabpage_list_wins(0) > 1 and is_sidebar(win) then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end,
    },
    session_lens = { picker = "telescope", load_on_setup = true },
  },
}
