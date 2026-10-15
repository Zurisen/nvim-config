-- Task runner that reads .vscode/tasks.json (plus npm scripts, make, etc.).
-- Supports dependsOn/dependsOrder, problem matchers ($msCompile, $tsc...) whose
-- errors become diagnostics + quickfix entries, and launch.json preLaunchTask.
local function overseer()
  return require("overseer")
end

-- The label of the tasks.json task with group { kind = "build", isDefault = true }.
-- (The installed overseer release ignores isDefault, so find it ourselves.)
local function default_build_task()
  local vs_util = require("overseer.vscode.vs_util")
  local file = vs_util.get_tasks_file(vim.fn.getcwd())
  local ok, content = pcall(vs_util.load_tasks_file, file or "")
  if not (file and ok and content and content.tasks) then
    return nil
  end
  for _, task in ipairs(content.tasks) do
    local g = task.group
    if type(g) == "table" and g.kind == "build" and g.isDefault then
      return task.label
    end
  end
end

local function build()
  -- Like VS Code's Ctrl+Shift+B: run the default build task, or pick one of
  -- the build tasks if none is marked as default.
  local name = default_build_task()
  if name then
    overseer().run_task({ name = name })
  else
    overseer().run_task({ tags = { overseer().TAG.BUILD }, first = false })
  end
  overseer().open({ enter = false })
end

local function rerun_last()
  local tasks = overseer().list_tasks({ sort = function(a, b) return a.id > b.id end })
  if tasks[1] then
    overseer().run_action(tasks[1], "restart")
  else
    vim.notify("No task has run yet", vim.log.levels.INFO)
  end
end

return {
  "stevearc/overseer.nvim",
  version = "*",
  cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerShell", "OverseerTaskAction" },
  keys = {
    { "<C-S-b>", build, mode = { "n", "i" }, desc = "Run build task" },
    { "<leader>rb", build, desc = "Run build task" },
    { "<leader>rr", "<cmd>OverseerRun<cr>", desc = "Run a task" },
    { "<leader>rt", "<cmd>OverseerToggle<cr>", desc = "Toggle task list / output" },
    { "<leader>rl", rerun_last, desc = "Re-run last task" },
  },
  opts = {
    task_list = { direction = "bottom" },
    -- Run tasks as plain processes, not in a terminal. On Windows the pseudo-
    -- terminal hard-wraps long lines (and `dotnet build` switches to its live
    -- "terminal logger"), which breaks problem matchers such as $msCompile.
    output = { use_terminal = false },
  },
}
