-- Claude Code in a sidebar: the real `claude` TUI in a terminal buffer, wired
-- back into Neovim over the same protocol as the VS Code extension. Claude sees
-- the current file/selection/diagnostics, can open files, uses your language
-- servers (LSP bridge), and shows proposed edits as side-by-side diffs.
-- Setup follows https://inacioklassmann.com/posts/claude-chat-nvim/

-- Like VS Code's Alt+K: insert an @-mention of the current file (with the
-- selected line range, e.g. "@src/Foo.cs#10-25") into Claude's prompt. Focus
-- stays in the editor so you can collect several references before asking.
local function mention()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("Claude: not a file buffer", vim.log.levels.WARN)
    return
  end

  local cwd = require("claude-chat.config").ensure().cwd or vim.fn.getcwd()
  local ref = vim.fs.relpath(cwd, file) or vim.fn.fnamemodify(file, ":.")

  if vim.fn.mode():match("[vV\22]") then
    local s, e = vim.fn.line("v"), vim.fn.line(".")
    if s > e then
      s, e = e, s
    end
    ref = s == e and ("%s#%d"):format(ref, s) or ("%s#%d-%d"):format(ref, s, e)
    vim.cmd("normal! \27") -- leave visual mode
  end

  local ui = require("claude-chat.ui")
  local editor_win = vim.api.nvim_get_current_win()
  if not ui.is_open() then
    ui.open() -- opens (and focuses) the sidebar...
    vim.cmd.stopinsert()
    vim.api.nvim_set_current_win(editor_win) -- ...so come straight back
  end

  -- A freshly started TUI ignores input until its prompt ("❯") is drawn, so
  -- wait for that (up to 15s) before typing the mention.
  local function prompt_ready()
    for _, line in ipairs(vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)) do
      if line:find("\u{276F}", 1, true) then
        return true
      end
    end
  end
  local tries = 0
  local function send()
    if not (ui.job and ui.buf and vim.api.nvim_buf_is_valid(ui.buf)) then
      return
    end
    if prompt_ready() or tries >= 75 then
      vim.fn.chansend(ui.job, "@" .. ref .. " ")
    else
      tries = tries + 1
      vim.defer_fn(send, 200)
    end
  end
  send()
end

-- Fullscreen Claude (Home inside Claude): the same conversation in a window
-- covering the whole editor. Home again goes back to the sidebar; so does
-- leaving it any other way (Ctrl+Shift+I, Ctrl+P, a diff opening...).
local zoom_win

local function zoom_layout()
  return {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = math.max(1, vim.o.lines - vim.o.cmdheight),
    zindex = 40, -- below pickers and popups
  }
end

local function toggle_zoom()
  local ui = package.loaded["claude-chat.ui"]
  if zoom_win and vim.api.nvim_win_is_valid(zoom_win) then
    local win = zoom_win
    zoom_win = nil
    vim.api.nvim_win_close(win, true)
    if ui and ui.is_open() then
      vim.api.nvim_set_current_win(ui.win) -- claude-chat goes back to typing
    end
    return
  end
  if not (ui and ui.buf and vim.api.nvim_buf_is_valid(ui.buf)) then
    return
  end
  zoom_win = vim.api.nvim_open_win(ui.buf, true, zoom_layout())
  vim.wo[zoom_win].winhighlight = "NormalFloat:Normal"
  vim.wo[zoom_win].winbar = " Claude (fullscreen, Home to go back)"
  vim.wo[zoom_win].number = false
  vim.wo[zoom_win].relativenumber = false
  vim.wo[zoom_win].signcolumn = "no"
  vim.cmd.startinsert()
end

return {
  "codegik/claude-chat.nvim",
  cmd = { "ClaudeChat", "ClaudeChatReset", "ClaudeChatFile", "ClaudeChatContinue", "ClaudeChatSessions" },
  keys = {
    { "<leader>ai", "<cmd>ClaudeChat<cr>", desc = "Toggle Claude sidebar" },
    { "<leader>af", "<cmd>ClaudeChatFile<cr>", desc = "Add current file to Claude" },
    { "<leader>as", mention, mode = { "n", "x" }, desc = "Reference file/selection in Claude" },
    { "<A-k>", mention, mode = { "n", "x" }, desc = "Reference file/selection in Claude" },
    { "<leader>ac", "<cmd>ClaudeChatContinue<cr>", desc = "Continue last conversation" },
    { "<leader>ar", "<cmd>ClaudeChatSessions<cr>", desc = "Resume a past conversation" },
    { "<leader>an", "<cmd>ClaudeChatReset<cr>", desc = "New conversation" },
  },
  init = function()
    local group = vim.api.nvim_create_augroup("user-claude-zoom", { clear = true })
    vim.api.nvim_create_autocmd("WinLeave", {
      group = group,
      callback = function()
        local win = vim.api.nvim_get_current_win()
        if win == zoom_win then
          zoom_win = nil
          vim.schedule(function()
            pcall(vim.api.nvim_win_close, win, true)
          end)
        end
      end,
    })
    vim.api.nvim_create_autocmd("VimResized", {
      group = group,
      callback = function()
        if zoom_win and vim.api.nvim_win_is_valid(zoom_win) then
          vim.api.nvim_win_set_config(zoom_win, zoom_layout())
        end
      end,
    })

    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("user-claude-keys", { clear = true }),
      callback = function(args)
        local ui = package.loaded["claude-chat.ui"]
        if not (ui and ui.buf == args.buf) then
          return
        end
        vim.keymap.set({ "t", "n" }, "<Home>", toggle_zoom, { buffer = args.buf, desc = "Claude fullscreen (toggle)" })
        -- Claude Code draws the conversation itself (fullscreen renderer), so
        -- the terminal buffer only holds the visible screen: scrolling is done
        -- by Claude. While typing, PageUp/PageDown (and Ctrl+Home/Ctrl+End)
        -- already go to it; from normal mode, pass them on and resume typing.
        for key, seq in pairs({ ["<PageUp>"] = "\27[5~", ["<PageDown>"] = "\27[6~" }) do
          vim.keymap.set("n", key, function()
            vim.fn.chansend(ui.job, seq)
            vim.cmd.startinsert()
          end, { buffer = args.buf, desc = "Scroll the Claude conversation" })
        end
      end,
    })
  end,
  opts = {
    width = 90,
    position = "right",
    -- Inside the sidebar (terminal mode): <C-h>/<C-l> move between windows,
    -- <C-q> hides it (Claude keeps running), <Home> fullscreen (see above).
    -- <C-j>/<C-k> are left to Claude (new line / delete to end of line): the
    -- sidebar is full height, so there is never a window above or below it.
    keymaps = { nav = { up = false, down = false } },
  },
}
