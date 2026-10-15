-- Entry point. Each concern lives in its own module under lua/config/,
-- and every plugin spec lives under lua/plugins/ (loaded by lazy.nvim).

-- Leader must be set before plugins and keymaps are loaded.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.navigation")
require("config.autocmds")
require("config.lazy")
