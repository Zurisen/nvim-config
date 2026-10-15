-- Toggleable terminal inside Neovim, plus lazygit in a floating window.
local lazygit -- created on first use

local function toggle_lazygit()
  if not lazygit then
    lazygit = require("toggleterm.terminal").Terminal:new({
      cmd = "lazygit",
      dir = "git_dir", -- open at the repo root of the current file
      direction = "float",
      hidden = true, -- not part of the normal <C-\> terminal list
      float_opts = { width = math.floor(vim.o.columns * 0.95), height = math.floor(vim.o.lines * 0.9) },
      -- Our lazygit settings live in this config repo (see lazygit.yml).
      env = { LG_CONFIG_FILE = vim.fn.stdpath("config") .. "/lazygit.yml" },
      on_open = function(term)
        vim.cmd.startinsert()
        -- Send Esc straight to lazygit instead of waiting for the global
        -- <Esc><Esc> "exit terminal mode" mapping.
        vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, nowait = true })
      end,
      on_exit = function()
        lazygit = nil -- start fresh next time (e.g. in another repo)
      end,
    })
  end
  lazygit:toggle()
end

-- Called by lazygit (via `nvim --server`, see lazygit.yml) to open files here.
function _G.LazygitHide()
  if lazygit and lazygit:is_open() then
    lazygit:close()
  end
  vim.cmd.stopinsert() -- leave terminal-insert mode so nothing gets typed into the file
  return 0
end

function _G.LazygitGoto(line)
  pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
  vim.cmd("normal! zz")
  return 0
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { [[<C-\>]], desc = "Toggle terminal" },
    { "<leader>ut", "<cmd>ToggleTerm direction=float<CR>", desc = "Floating terminal" },
    { "<leader>uv", "<cmd>ToggleTerm direction=vertical size=80<CR>", desc = "Vertical terminal" },
    { "<leader>gg", toggle_lazygit, desc = "Lazygit" },
  },
  opts = {
    open_mapping = [[<C-\>]],
    direction = "horizontal",
    size = 15,
    shell = "powershell.exe -NoLogo",
    float_opts = { border = "rounded" },
  },
}
