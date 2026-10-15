-- Debugging via the Debug Adapter Protocol (the same adapters VS Code uses).
--   C#         -> netcoredbg
--   Python     -> debugpy (via nvim-dap-python)
--   TypeScript -> js-debug (pwa-node)
-- Adapters are installed by Mason (see lsp.lua). A .vscode/launch.json in the
-- project is also picked up automatically and offered alongside these configs.
local mason = vim.fn.stdpath("data") .. "/mason/packages"

-- Run a command without blocking the UI, from inside a dap configuration.
-- nvim-dap evaluates config functions in a coroutine, so we can yield here.
local function run_async(cmd, opts)
  local co = assert(coroutine.running(), "must be called from a coroutine")
  vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {}), function(res)
    vim.schedule(function()
      coroutine.resume(co, res)
    end)
  end)
  return coroutine.yield()
end

local function select_async(items, prompt)
  local co = assert(coroutine.running(), "must be called from a coroutine")
  vim.ui.select(items, { prompt = prompt }, function(choice)
    coroutine.resume(co, choice)
  end)
  return coroutine.yield()
end

-- Find the .csproj for the current file, build it, and return its output dll.
local function build_dotnet_project()
  local csproj = vim.fs.find(function(name)
    return name:match("%.csproj$")
  end, { upward = true, path = vim.fn.expand("%:p:h") })[1]
  if not csproj then
    return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
  end

  local name = vim.fn.fnamemodify(csproj, ":t:r")
  vim.notify("Building " .. name .. "...")
  local res = run_async({ "dotnet", "build", csproj, "-c", "Debug", "--nologo", "-v", "q" })
  if res.code ~= 0 then
    vim.notify("Build failed:\n" .. res.stdout, vim.log.levels.ERROR)
    return require("dap").ABORT
  end

  local dlls = vim.fn.glob(vim.fs.dirname(csproj) .. "/bin/Debug/*/" .. name .. ".dll", false, true)
  if #dlls == 1 then
    return dlls[1]
  elseif #dlls > 1 then
    return select_async(dlls, "Select target framework") or require("dap").ABORT
  end
  -- AssemblyName differs from the project name; ask for the path.
  return vim.fn.input("Path to dll: ", vim.fs.dirname(csproj) .. "/bin/Debug/", "file")
end

-- The folder whose .vscode/launch.json applies to a buffer: the nearest one
-- above its file. Not the working directory, which a restored session or
-- neo-tree can leave on a parent folder (e.g. C:\Code instead of the repo).
local function launch_json_root(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local start = vim.fn.filereadable(file) == 1 and file or vim.fn.getcwd()
  return vim.fs.root(start, function(name, path)
    return name == ".vscode" and vim.uv.fs_stat(path .. "/.vscode/launch.json") ~= nil
  end) or vim.fn.getcwd()
end

-- Copy of a launch.json value with ${workspaceFolder} pointing at `root`.
-- nvim-dap would otherwise expand it to the working directory.
local function with_workspace_folder(value, root)
  if type(value) == "string" then
    value = value:gsub("%${workspaceFolder}", function() return root end)
    return (value:gsub("%${workspaceFolderBasename}", function() return vim.fs.basename(root) end))
  elseif type(value) == "table" then
    local copy = {}
    for k, v in pairs(value) do
      copy[k] = with_workspace_folder(v, root)
    end
    return copy
  end
  return value
end

-- Configurations from the launch.json that applies to `bufnr`, plus its path.
-- Used for both F5 (as nvim-dap's launch.json provider) and Ctrl+F5.
local function launch_json_configs(bufnr)
  local root = launch_json_root(bufnr)
  local path = root .. "/.vscode/launch.json"
  local ok, configs = pcall(require("dap.ext.vscode").getconfigs, path)
  if not ok then
    vim.notify("Can't read " .. path .. ":\n" .. configs, vim.log.levels.WARN)
    return {}, path
  end
  return vim.tbl_map(function(c)
    return with_workspace_folder(c, root)
  end, configs), path
end

-- Like VS Code's Ctrl+F5: start a .vscode/launch.json configuration's program
-- as a normal process, without the debugger.
local function expand(s)
  if type(s) ~= "string" then
    return s
  end
  local vars = {
    cwd = vim.fn.getcwd(),
    file = vim.fn.expand("%:p"),
    fileDirname = vim.fn.expand("%:p:h"),
  }
  return (s:gsub("%${(%w+)}", function(v)
    return vars[v]
  end))
end

local function run_without_debugging()
  local configs, path = launch_json_configs(vim.api.nvim_get_current_buf())
  configs = vim.tbl_filter(function(c)
    return c.request == "launch" and type(c.program) == "string"
  end, configs)
  if #configs == 0 then
    vim.notify("No launch configuration with a program in " .. path, vim.log.levels.WARN)
    return
  end

  local function start(c)
    local program = vim.fn.simplify(expand(c.program))
    if vim.fn.filereadable(program) == 0 then
      vim.notify("Not built yet: " .. program .. "\nBuild first (Ctrl+Shift+B)", vim.log.levels.ERROR)
      return
    end
    local cmd = program:match("%.dll$") and { "dotnet", program } or { program }
    for _, arg in ipairs(c.args or {}) do
      table.insert(cmd, expand(arg))
    end
    local job = vim.fn.jobstart(cmd, {
      cwd = c.cwd and vim.fn.simplify(expand(c.cwd)) or vim.fn.getcwd(),
      env = c.env,
      detach = true, -- keeps running if Neovim exits
    })
    if job > 0 then
      vim.notify("Started (no debugger): " .. c.name)
    else
      vim.notify("Failed to start " .. program, vim.log.levels.ERROR)
    end
  end

  if #configs == 1 then
    start(configs[1])
  else
    vim.ui.select(configs, {
      prompt = "Run without debugging",
      format_item = function(c)
        return c.name
      end,
    }, function(c)
      if c then
        start(c)
      end
    end)
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    -- Function keys follow Visual Studio / VS Code.
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Start / continue" },
      { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: Stop" },
      { "<C-F5>", run_without_debugging, desc = "Run without debugging (launch.json)" },
      { "<leader>dR", run_without_debugging, desc = "Run without debugging (launch.json)" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Start / continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last configuration" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate expression" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({}) -- show variable values inline

      -- Open the UI when a session starts, close it when it ends.
      dap.listeners.after.event_initialized["dapui"] = dapui.open
      dap.listeners.before.event_terminated["dapui"] = dapui.close
      dap.listeners.before.event_exited["dapui"] = dapui.close

      -- F5 offers the launch.json found above the current file, not the one
      -- in the working directory (see launch_json_root).
      dap.providers.configs["dap.launch.json"] = launch_json_configs

      -- Nerd Font icons, written as escapes so they survive any editor.
      vim.fn.sign_define("DapBreakpoint", { text = "\u{f111}", texthl = "DiagnosticError" }) --
      vim.fn.sign_define("DapBreakpointCondition", { text = "\u{f059}", texthl = "DiagnosticWarn" }) --
      vim.fn.sign_define("DapBreakpointRejected", { text = "\u{f06a}", texthl = "DiagnosticHint" }) --
      vim.fn.sign_define("DapStopped", { text = "\u{f061}", texthl = "DiagnosticOk", linehl = "Visual" }) --

      -- C# -----------------------------------------------------------------
      dap.adapters.coreclr = {
        type = "executable",
        command = mason .. "/netcoredbg/netcoredbg/netcoredbg.exe",
        args = { "--interpreter=vscode" },
      }
      dap.adapters.netcoredbg = dap.adapters.coreclr -- alias used by some launch.json files

      -- netcoredbg on Windows only resolves breakpoints in paths with
      -- backslashes, but buffer names can contain "/". Rewrite them before
      -- the breakpoints are sent (this event fires before nvim-dap sends them).
      dap.listeners.before.event_initialized["netcoredbg-paths"] = function(session)
        if session.config.type ~= "coreclr" or session.request_patched then
          return
        end
        local request = session.request
        session.request = function(self, command, args, ...)
          if command == "setBreakpoints" and args and args.source and args.source.path then
            args.source.path = args.source.path:gsub("/", "\\")
          end
          return request(self, command, args, ...)
        end
        session.request_patched = true
      end
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Build & launch project",
          request = "launch",
          program = build_dotnet_project,
          cwd = "${fileDirname}",
        },
        {
          type = "coreclr",
          name = "Attach to process",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }

      -- Python -------------------------------------------------------------
      -- debugpy runs from Mason's venv; your code runs with the active
      -- virtualenv (VIRTUAL_ENV / .venv) if there is one.
      require("dap-python").setup(mason .. "/debugpy/venv/Scripts/python.exe")

      -- TypeScript / JavaScript --------------------------------------------
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { mason .. "/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
        },
      }
      dap.adapters.node = dap.adapters["pwa-node"] -- alias used by launch.json files
      for _, ft in ipairs({ "typescript", "javascript" }) do
        dap.configurations[ft] = {
          {
            type = "pwa-node",
            name = "Launch current file (node)",
            request = "launch",
            program = "${file}", -- Node 23.6+ runs .ts files directly
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            name = "Attach to process",
            request = "attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  },
}
