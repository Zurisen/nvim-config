-- Harpoon: pin the handful of files you're working on (per project folder)
-- and jump to them with one key.
local function list()
  return require("harpoon"):list()
end

local keys = {
  { "<leader>ha", function() list():add() end, desc = "Pin file to harpoon" },
  {
    "<leader>hh",
    function()
      local harpoon = require("harpoon")
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end,
    desc = "Harpoon menu (reorder / remove pins)",
  },
  { "<leader>hp", function() list():prev() end, desc = "Previous pinned file" },
  { "<leader>hn", function() list():next() end, desc = "Next pinned file" },
}
for i = 1, 5 do
  table.insert(keys, { "<A-" .. i .. ">", function() list():select(i) end, desc = "Go to pinned file " .. i })
end

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = keys,
  config = function()
    require("harpoon"):setup({
      settings = {
        save_on_toggle = true, -- edits in the menu are saved when it closes
      },
    })
  end,
}
