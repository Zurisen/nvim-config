-- When started on a file outside the current folder (e.g. `nvim C:\code\app\Program.cs`
-- from your home dir), switch to that file's project root. Telescope, neo-tree and
-- neotest all work from the current folder, and scanning your whole home dir is slow.
local project_files = {
  ["package.json"] = true, ["pyproject.toml"] = true, ["requirements.txt"] = true,
  ["setup.py"] = true, ["setup.cfg"] = true,
}
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("user-project-root", { clear = true }),
  callback = function()
    if vim.fn.argc() ~= 1 then
      return
    end
    local file = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
    if vim.fn.filereadable(file) == 0 then
      return
    end
    -- Only take over when started from a "broad" folder (home dir or a drive root);
    -- if you cd'd somewhere deliberately, keep it.
    local cwd = vim.fs.normalize(vim.fn.getcwd()):lower()
    local home = vim.fs.normalize(vim.uv.os_homedir()):lower()
    if cwd ~= home and not cwd:match("^%a:/?$") then
      return
    end
    -- Most specific first: a solution beats .git (which may be a big monorepo).
    local root = vim.fs.root(file, function(name)
      return name:match("%.slnx?$") ~= nil
    end)
      or vim.fs.root(file, function(name)
        return project_files[name] ~= nil
      end)
      or vim.fs.root(file, ".git")
      or vim.fs.root(file, function(name)
        return name:match("%.csproj$") ~= nil
      end)
    if root then
      vim.fn.chdir(root)
    end
  end,
})

-- Save edited files when you switch to Claude, a terminal or lazygit, or when
-- Neovim loses focus. Claude edits files on disk, so it then works on your
-- latest code, and the reload below brings both your edits and Claude's into
-- the buffer (like VS Code saving before Claude edits). Format-on-save runs too.
local function save_modified_files()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.bo[buf].modifiable
      and not vim.bo[buf].readonly and vim.api.nvim_buf_get_name(buf) ~= "" then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! update")
      end)
    end
  end
end
vim.api.nvim_create_autocmd({ "TermEnter", "BufEnter", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("user-autosave", { clear = true }),
  callback = function(args)
    if args.event == "BufEnter" and vim.bo[args.buf].buftype ~= "terminal" then
      return -- only when entering a terminal (Claude, lazygit, shells)
    end
    save_modified_files()
  end,
})

-- Reload buffers whose files were changed outside Neovim (Claude, lazygit,
-- builds...). Neovim only checks on a few events, and typing in the Claude
-- sidebar triggers none of them, so also check once a second. A reloaded
-- buffer is re-sent to the language server, which keeps it in sync.
vim.o.autoread = true
local function checktime()
  if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
    vim.cmd("silent! checktime")
  end
end
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "WinEnter", "TermLeave", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("user-checktime", { clear = true }),
  callback = checktime,
})
vim.uv.new_timer():start(1000, 1000, vim.schedule_wrap(checktime))

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("user-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
