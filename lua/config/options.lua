local opt = vim.opt

-- Font ---------------------------------------------------------------------
-- In a terminal, Neovim draws with the terminal's font (Windows Terminal is
-- set to "JetBrainsMono NF"). This flag tells plugins that Nerd Font icons
-- are available, so they render icons instead of plain-text fallbacks.
vim.g.have_nerd_font = true

-- Only used by GUI frontends (Neovide, nvim-qt); ignored in a terminal.
vim.o.guifont = "JetBrainsMono NF:h11"

-- File types ---------------------------------------------------------------
-- Neovim doesn't know .xaml; treat it as XML so it gets XML highlighting and
-- the XML language server (lemminx, see lsp.lua).
vim.filetype.add({ extension = { xaml = "xml" } })

-- UI -----------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes" -- always show, so text doesn't shift when diagnostics appear
opt.scrolloff = 10
opt.showmode = false -- the statusline already shows the mode
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.winborder = "rounded" -- borders on floating windows (hover, signature help)

-- Editing ------------------------------------------------------------------
opt.mouse = "a"
opt.undofile = true
opt.breakindent = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.confirm = true -- ask to save instead of failing on :q with unsaved changes

-- Sync with the Windows clipboard. Scheduled because it can slow startup.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- Search -------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- live preview of :s substitutions

-- Timing -------------------------------------------------------------------
opt.updatetime = 250
opt.timeoutlen = 300
