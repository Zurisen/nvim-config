-- General editor quality-of-life plugins.

-- Leave the side-by-side git diff (<leader>gd): close the old-version window
-- and turn diff mode off. Diff mode belongs to the window, so without this a
-- file opened later in the same window would also show up as a diff.
local function close_git_diff()
  local closed, any_diff = false, false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if name:match("^gitsigns://") then
      pcall(vim.api.nvim_win_close, win, true)
      closed = true
    elseif vim.wo[win].diff then
      any_diff = true
    end
  end
  if closed or any_diff then
    vim.cmd("diffoff!")
  end
  return closed
end

-- The git-changes window (<leader>gs) is neo-tree's git_status view. It stays
-- open (opened at startup in a git repo) while the file explorer is a popup.
local function is_git_tree(buf)
  return vim.bo[buf].filetype == "neo-tree" and vim.b[buf].neo_tree_source == "git_status"
end

local function git_tree_visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_git_tree(vim.api.nvim_win_get_buf(win)) then
      return true
    end
  end
  return false
end

-- Move the code window to the next / previous / first git change (hunk) of
-- its file. Works from the code or from the git-changes window.
local function jump_change(direction)
  local target = vim.api.nvim_get_current_win()
  if vim.bo.filetype == "neo-tree" then
    target = require("config.navigation").editor_win()
  end
  if not target then
    return
  end
  local ok, gs = pcall(require, "gitsigns")
  local hunks = ok and gs.get_hunks(vim.api.nvim_win_get_buf(target)) or {}
  if #hunks == 0 then
    if direction ~= "first" then
      vim.notify("No changes in this file", vim.log.levels.INFO)
    end
    return
  end
  local starts = {}
  for _, h in ipairs(hunks) do
    table.insert(starts, math.max(1, h.added.start))
  end
  table.sort(starts)
  local line = vim.api.nvim_win_get_cursor(target)[1]
  local dest
  if direction == "next" then
    for _, s in ipairs(starts) do
      if s > line then
        dest = s
        break
      end
    end
    dest = dest or starts[1] -- wrap around
  elseif direction == "prev" then
    for i = #starts, 1, -1 do
      if starts[i] < line then
        dest = starts[i]
        break
      end
    end
    dest = dest or starts[#starts]
  else
    dest = starts[1]
  end
  vim.api.nvim_win_set_cursor(target, { dest, 0 })
  vim.api.nvim_win_call(target, function()
    vim.cmd("normal! zz")
  end)
end

-- Show the file selected in the git-changes window in the code window, at its
-- first change, while the cursor stays in the git-changes window.
local function show_selected_change()
  local state = require("neo-tree.sources.manager").get_state("git_status")
  local node = state and state.tree and state.tree:get_node()
  if not node or node.type ~= "file" or vim.fn.filereadable(node.path) == 0 then
    return -- folders, deleted files
  end
  close_git_diff()
  local target = require("config.navigation").editor_win()
  if not target then
    return
  end
  local shown = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(target))
  if vim.fs.normalize(shown):lower() == vim.fs.normalize(node.path):lower() then
    return
  end
  vim.api.nvim_win_call(target, function()
    vim.cmd("edit " .. vim.fn.fnameescape(node.path))
  end)
  -- gitsigns needs a moment to compute the changes of a freshly opened file.
  local buf, tries = vim.api.nvim_win_get_buf(target), 0
  local function to_first_change()
    tries = tries + 1
    if not vim.api.nvim_win_is_valid(target) or vim.api.nvim_win_get_buf(target) ~= buf then
      return
    end
    local ok, gs = pcall(require, "gitsigns")
    if ok and #(gs.get_hunks(buf) or {}) > 0 then
      jump_change("first")
    elseif tries < 20 then
      vim.defer_fn(to_first_change, 100)
    end
  end
  vim.defer_fn(to_first_change, 100)
end

return {
  -- Popup that shows available keymaps after pressing <leader> (or any prefix).
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>a", group = "AI / Claude" },
        { "<leader>r", group = "Run tasks" },
        { "<leader>s", group = "Search" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Debug" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Harpoon (pinned files)" },
        { "<leader>w", group = "Session" },
        { "<leader>x", group = "Problems & lists (Trouble)" },
        { "<leader>t", group = "Test" },
        { "<leader>u", group = "Toggle / Terminal" },
      },
    },
  },

  -- File explorer sidebar.
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle reveal filesystem<CR>", desc = "File explorer (popup)" },
      -- Only the files with git changes (like lazygit's Files panel).
      { "<leader>gs", "<cmd>Neotree toggle git_status<CR>", desc = "Git changes window (toggle)" },
    },
    init = function()
      local group = vim.api.nvim_create_augroup("user-neotree", { clear = true })

      -- Close the file explorer as soon as focus moves to another normal
      -- window. The git-changes window stays: only <leader>gs closes it.
      -- Floating windows (neo-tree's own prompts, pickers) don't count.
      vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "neo-tree" or is_git_tree(args.buf) then
            return
          end
          vim.schedule(function()
            local win = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_config(win).relative ~= ""
              or vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
              return
            end
            vim.cmd("Neotree close filesystem")
          end)
        end,
      })

      -- Open the git-changes window at startup in a git repository (plain
      -- `nvim` or `nvim .`; not when opening a specific file, e.g. as git's
      -- or lazygit's editor). Also after restoring a session.
      local function show_git_tree()
        if not vim.fs.root(vim.fn.getcwd(), ".git") or git_tree_visible() then
          return
        end
        -- `nvim .` leaves an empty directory buffer: swap it for a blank one.
        local buf = vim.api.nvim_get_current_buf()
        if vim.fn.isdirectory(vim.api.nvim_buf_get_name(buf)) == 1 then
          vim.cmd("enew")
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
        vim.cmd("Neotree show git_status")
      end
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        callback = function()
          if vim.fn.argc() == 0 or vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            vim.defer_fn(show_git_tree, 300) -- after the session is restored
          end
        end,
      })
      vim.api.nvim_create_autocmd("SessionLoadPost", {
        group = group,
        callback = function()
          vim.defer_fn(show_git_tree, 100)
        end,
      })

      -- When the selected line is wider than the git window, scroll the
      -- window sideways just enough to show the whole name, but never past
      -- its start (a name longer than the window keeps its beginning visible).
      -- Lines that fit scroll back.
      local function reveal_full_name()
        local win = vim.api.nvim_get_current_win()
        local line = vim.api.nvim_get_current_line()
        local overflow = vim.fn.strdisplaywidth(line) - vim.api.nvim_win_get_width(win)
        local leftcol = vim.fn.winsaveview().leftcol
        if overflow <= 0 then
          if leftcol ~= 0 then
            vim.fn.winrestview({ leftcol = 0 })
          end
          return
        end
        local state = require("neo-tree.sources.manager").get_state("git_status")
        local node = state and state.tree and state.tree:get_node()
        local start = node and line:find(node.name, 1, true) or 1
        local target = math.min(overflow, vim.fn.strdisplaywidth(line:sub(1, start - 1)))
        if leftcol ~= target then
          local row = vim.api.nvim_win_get_cursor(win)[1]
          vim.api.nvim_win_set_cursor(win, { row, start - 1 }) -- cursor on the name, so it stays in view
          vim.fn.winrestview({ leftcol = target })
        end
      end

      -- Moving through the git-changes window shows each file in the code
      -- window straight away (at its first change); Enter moves into it.
      local timer = vim.uv.new_timer()
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        callback = function(args)
          if is_git_tree(args.buf) then
            reveal_full_name()
            timer:stop()
            timer:start(120, 0, vim.schedule_wrap(show_selected_change))
          end
        end,
      })

      -- Keep the git-changes window current: refresh it when files are saved
      -- or changed on disk (Claude, git), when coming back from Claude or a
      -- terminal, and when entering it.
      local last_refresh = 0
      vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost", "FocusGained", "TermLeave", "BufEnter" }, {
        group = group,
        callback = function(args)
          if args.event == "BufEnter" and not is_git_tree(args.buf) then
            return
          end
          if not git_tree_visible() or vim.uv.now() - last_refresh < 500 then
            return
          end
          last_refresh = vim.uv.now()
          vim.schedule(function()
            require("neo-tree.sources.manager").refresh("git_status")
          end)
        end,
      })

      -- Next / previous change of the file in the code window, from the code
      -- or from the git-changes window (Windows Terminal sends these, see README).
      vim.keymap.set("n", "<C-S-j>", function() jump_change("next") end, { desc = "Next git change" })
      vim.keymap.set("n", "<C-S-k>", function() jump_change("prev") end, { desc = "Previous git change" })
    end,
    opts = {
      -- Changing the explorer's root must not change the tab's working
      -- directory: neo-tree did that with `tcd`, and sessions then restored it.
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        -- A popup, so it doesn't take the git-changes window's place.
        window = { position = "float" },
        hijack_netrw_behavior = "disabled", -- `nvim .` shows the git window instead
      },
      buffers = { bind_to_cwd = false },
      git_status = {
        window = { position = "left" },
        -- Merge chains of folders that only contain one folder (like VS
        -- Code's compact folders) ...
        group_empty_dirs = true,
        components = {
          -- ... and show only the last two folders of such a chain, e.g.
          -- "Views/Dialogs" instead of "src\MyApp\...\Views\Dialogs".
          name = function(config, node, state)
            local item = require("neo-tree.sources.common.components").name(config, node, state)
            if node.type == "directory" and node:get_depth() > 1 then
              local parts = vim.split(item.text, "[\\/]", { trimempty = true })
              item.text = table.concat(vim.list_slice(parts, math.max(1, #parts - 1)), "/")
            end
            return item
          end,
        },
        renderers = {
          -- The default layout cuts long names to keep the status icons on the
          -- right edge. Put the icons after the full name instead; the window
          -- scrolls sideways for long names (see reveal_full_name).
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "diagnostics" },
            { "git_status" },
          },
        },
      },
      window = {
        mappings = {
          -- neo-tree binds Space (expand/collapse) in its windows, which blocks
          -- every <leader> key there (e.g. <leader>gs from the git window).
          -- Enter still expands/collapses folders.
          ["<space>"] = "none",
          -- neo-tree uses Ctrl+Shift+I for "invert selection"; keep it as the
          -- global "switch to Claude" key in its windows too.
          ["<C-S-i>"] = function()
            require("config.navigation").toggle_claude_focus()
          end,
        },
      },
      event_handlers = {
        -- Leave any git diff before a file is opened from the explorer, so it
        -- opens normally (and not into the diff's old-version window).
        {
          event = "file_open_requested",
          handler = function()
            close_git_diff()
          end,
        },
        -- Opening a file from the explorer popup also closes it (neo-tree may
        -- switch windows without firing WinLeave). The git window stays open.
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close", source = "filesystem" })
          end,
        },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)

      -- The git-changes tree (<leader>gs) asks git for every untracked *and
      -- ignored* file individually, then skips the ignored ones. In a monorepo
      -- that is ~80k build-output files and freezes Neovim for seconds. Don't
      -- request ignored files while building that view (15 entries, 0.2s).
      local items = require("neo-tree.sources.git_status.lib.items")
      local git = require("neo-tree.git")
      local get_git_status = items.get_git_status
      items.get_git_status = function(state)
        local status = git.status
        git.status = function(path, base, skip_bubbling, status_opts)
          status_opts = vim.tbl_extend("force", status_opts or {}, { ignored = "no" })
          return status(path, base, skip_bubbling, status_opts)
        end
        local ok, err = pcall(get_git_status, state)
        git.status = status
        if not ok then
          error(err)
        end
      end
    end,
  },

  -- Git changes in the sign column, plus hunk actions.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local map = function(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = buf, desc = desc })
        end
        map("]h", function() gs.nav_hunk("next") end, "Next git hunk")
        map("[h", function() gs.nav_hunk("prev") end, "Previous git hunk")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gb", gs.blame_line, "Blame line")
        map("<leader>gd", function()
          if not close_git_diff() then
            gs.diffthis()
          end
        end, "Toggle side-by-side git diff")
      end,
      -- Tint the whole row of added / changed lines, not just the sign band.
      linehl = true,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      -- A soft green (Dracula's green at ~13% over its background), so the
      -- rows stand out without being bright. Re-applied if the theme reloads.
      local function row_colors()
        for _, group in ipairs({ "GitSignsAddLn", "GitSignsChangeLn", "GitSignsChangedeleteLn" }) do
          vim.api.nvim_set_hl(0, group, { bg = "#2d453f" })
        end
      end
      row_colors()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("user-gitsigns-rows", { clear = true }),
        callback = row_colors,
      })
    end,
  },

  -- Statusline.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "dracula-nvim", globalstatus = true } },
  },

  -- Auto-close brackets and quotes.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
