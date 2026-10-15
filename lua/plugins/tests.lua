-- Run and debug tests from inside Neovim.
--   C#         -> neotest-vstest (xUnit, NUnit, MSTest; debugs via netcoredbg)
--   Python     -> neotest-python (pytest; debugs via debugpy)
--   TypeScript -> neotest-vitest / neotest-jest (each activates only in
--                 projects that use that framework)
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
    "nsidorenco/neotest-vstest",
    "nvim-neotest/neotest-python",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run tests in file" },
    { "<leader>tA", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run all tests" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Re-run last test" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop running tests" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle test explorer" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show test output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
    { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Watch file (re-run on save)" },
    { "]t", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next failed test" },
    { "[t", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Previous failed test" },
  },
  config = function()
    local lib = require("neotest.lib")

    -- Folders never worth scanning for tests (they can hold thousands of files).
    local skip_dirs = {
      [".git"] = true, [".vs"] = true, [".idea"] = true, [".venv"] = true, ["venv"] = true,
      ["node_modules"] = true, ["bin"] = true, ["obj"] = true, ["dist"] = true,
      ["build"] = true, ["__pycache__"] = true, ["packages"] = true, ["TestResults"] = true,
    }

    -- Must be set before neotest-vstest is required.
    vim.g.neotest_vstest = {
      dap_settings = { type = "coreclr" }, -- the netcoredbg adapter from debug.lua
      -- The default scans every folder below the cwd for .sln files, which
      -- freezes Neovim when started from a broad folder like your home dir.
      broad_recursive_discovery = false,
      -- The default hidden-dir filter only matches "/", not Windows "\".
      discovery_directory_filter = function(search_path)
        return search_path:match("[/\\]%.") ~= nil
      end,
    }

    -- Only claim folders that are actually .NET projects. Without this,
    -- neotest-vstest claims any folder and neotest scans all of it.
    local vstest = require("neotest-vstest")
    local vstest_root = vstest.root
    vstest.root = function(path)
      if lib.files.match_root_pattern("*.sln", "*.slnx", "*.csproj")(path) then
        return vstest_root(path)
      end
    end

    -- Uses the project's virtualenv (.venv / VIRTUAL_ENV) when present.
    local python = require("neotest-python")({ runner = "pytest", dap = { justMyCode = false } })
    -- neotest-python only recognises pyproject.toml/setup.cfg/pytest.ini/
    -- setup.py; also accept plain projects with a requirements.txt or a git repo.
    local python_root = python.root
    python.root = function(path)
      return python_root(path) or lib.files.match_root_pattern("requirements.txt", ".git")(path)
    end

    require("neotest").setup({
      adapters = {
        vstest,
        python,
        require("neotest-vitest"),
        require("neotest-jest")({ jestCommand = "npx jest" }),
      },
      discovery = {
        filter_dir = function(name)
          return not skip_dirs[name]
        end,
      },
      -- Failed-test messages appear as diagnostics on the failing line.
      diagnostic = { enabled = true },
      status = { virtual_text = true },
    })
  end,
}
