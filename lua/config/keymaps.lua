-- General keymaps. Plugin-specific keymaps live next to their plugin spec.
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Move between windows with Ctrl + h/j/k/l
map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })

-- Redraw the screen and even out window sizes in every tab (sidebars with a
-- fixed width, like Claude's, keep it). Ctrl+L is taken by window navigation.
local function fix_layout()
  vim.cmd("nohlsearch")
  vim.cmd("diffupdate")
  local tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("tabdo wincmd =")
  vim.api.nvim_set_current_tabpage(tab)
  vim.cmd("redraw!")
end
map("n", "<leader>ur", fix_layout, { desc = "Redraw and fix window layout" })

-- Re-balance windows automatically when the terminal is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("user-resize", { clear = true }),
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(tab)
  end,
})

-- Leave terminal mode with a double Esc
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Diagnostics
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to location list" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
