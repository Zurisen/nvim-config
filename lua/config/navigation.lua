-- VS Code-style window navigation.
--   Ctrl+Shift+P (or Ctrl+P)  quick-open a file (search bar at the top)
--   Ctrl+Shift+E              switch between the code and the git changes window
--                             (from anywhere else: go to the git changes window)
--   Ctrl+Shift+I              switch between Claude and the window you came from
-- Terminals normally send the same code for Ctrl+Shift+<key> and Ctrl+<key>, so
-- Windows Terminal is configured to send distinct "CSI u" codes for these three
-- (see README). Plain Ctrl+I can't be used: terminals send it as Tab.

local M = {}

local function is_editor_win(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "neo-tree"
    and vim.api.nvim_win_get_config(win).relative == "" -- not a floating window
end

-- The main editor window: the previous window if it holds a file, otherwise
-- the first window that does. nil if there is none.
function M.editor_win()
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and is_editor_win(prev) then
    return prev
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(win) then
      return win
    end
  end
end

-- The window files should open in: the code window, or a new one if there is
-- none (next to the git changes window, or left of the current window).
-- Never Claude, the git window, a terminal or a popup.
function M.code_win_for_open()
  local win = M.editor_win()
  if win then
    return win
  end
  local anchor, side = vim.api.nvim_get_current_win(), "left"
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.b[vim.api.nvim_win_get_buf(w)].neo_tree_source == "git_status" then
      anchor, side = w, "right"
    end
  end
  if vim.api.nvim_win_get_config(anchor).relative ~= "" then
    anchor = 0
  end
  return vim.api.nvim_open_win(vim.api.nvim_create_buf(true, false), false, { split = side, win = anchor })
end

-- Focus the main editor window.
function M.focus_editor()
  -- Coming from a floating window (lazygit, floating terminal): hide it so it
  -- doesn't cover the code. Its program keeps running.
  local cur = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(cur).relative ~= "" then
    pcall(vim.api.nvim_win_hide, cur)
  end
  local win = M.editor_win()
  if win then
    vim.api.nvim_set_current_win(win)
  end
end

function M.find_files()
  require("telescope.builtin").find_files(require("telescope.themes").get_dropdown({
    prompt_title = "Go to file",
    previewer = false,
    layout_config = { width = 0.6 },
  }))
end

local function is_git_window(win)
  return vim.b[vim.api.nvim_win_get_buf(win)].neo_tree_source == "git_status"
end

-- Ctrl+Shift+E: from the git changes window go to the code; from anywhere
-- else (code, Claude, terminals, popups) go to the git changes window,
-- opening it if it was closed.
function M.toggle_git_focus()
  local cur = vim.api.nvim_get_current_win()
  if is_git_window(cur) then
    M.focus_editor()
    return
  end
  if vim.api.nvim_win_get_config(cur).relative ~= "" then
    pcall(vim.api.nvim_win_hide, cur) -- popups (lazygit...) keep running
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_git_window(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd("Neotree focus git_status")
end

-- The window to return to from Claude: the last normal window you were in
-- before entering the Claude sidebar (code, git changes window, ...).
local claude_return_win
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("user-claude-return", { clear = true }),
  callback = function()
    local ui = package.loaded["claude-chat.ui"]
    if not (ui and ui.buf and vim.api.nvim_get_current_buf() == ui.buf) then
      return
    end
    local prev = vim.fn.win_getid(vim.fn.winnr("#"))
    if prev ~= 0 and vim.api.nvim_win_get_config(prev).relative == ""
      and vim.api.nvim_win_get_buf(prev) ~= ui.buf -- e.g. sidebar -> fullscreen Claude
    then
      claude_return_win = prev
    end
  end,
})

-- Ctrl+Shift+I: from Claude back to the window you came from; from anywhere
-- else to Claude (opening it if needed).
function M.toggle_claude_focus()
  local ui = require("claude-chat.ui")
  if ui.buf and vim.api.nvim_get_current_buf() == ui.buf then
    if claude_return_win and vim.api.nvim_win_is_valid(claude_return_win) then
      vim.api.nvim_set_current_win(claude_return_win)
    else
      M.focus_editor()
    end
    return
  end
  local cur = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(cur).relative == "" then
    claude_return_win = cur
  end
  if ui.is_open() then
    ui.focus()
  else
    vim.cmd("ClaudeChat")
  end
end

local map = function(lhs, fn, desc)
  -- Also in insert and terminal mode, so they work while typing or from the
  -- Claude sidebar / lazygit.
  vim.keymap.set({ "n", "i", "t" }, lhs, fn, { desc = desc })
end

map("<C-S-p>", M.find_files, "Go to file")
vim.keymap.set("n", "<C-p>", M.find_files, { desc = "Go to file" })
map("<C-S-e>", M.toggle_git_focus, "Switch: code / git changes window")
vim.keymap.set("x", "<C-S-e>", M.toggle_git_focus, { desc = "Switch: code / git changes window" })
map("<C-S-i>", M.toggle_claude_focus, "Switch: Claude / previous window")
-- From visual mode too: Claude keeps seeing the selection after focus moves.
vim.keymap.set("x", "<C-S-i>", M.toggle_claude_focus, { desc = "Switch: Claude / previous window" })

return M
