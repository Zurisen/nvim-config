-- Language servers, installed by Mason.
--   C#         -> roslyn (via roslyn.nvim)
--   Python     -> basedpyright (types) + ruff (lint)
--   TypeScript -> vtsls
--   Lua        -> lua_ls (for editing this config)
--   XML / XAML -> lemminx (markup errors, completion, folding, outline; it
--                 doesn't know WPF types - only Visual Studio has that)

-- Everything Mason should install. Formatters are used by conform.nvim (formatting.lua).
local tools = {
  -- LSP servers
  "roslyn",
  "basedpyright",
  "ruff",
  "vtsls",
  "lua-language-server",
  "lemminx",
  -- Formatters
  "csharpier",
  "prettierd",
  "stylua",
  -- Debug adapters (used by nvim-dap, see debug.lua)
  "netcoredbg",
  "debugpy",
  "js-debug-adapter",
}

return {
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        -- Provides "roslyn", the same C# server build VS Code ships.
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = { ensure_installed = tools },
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- Calls vim.lsp.enable() for every server Mason installed.
      -- roslyn_ls is excluded because roslyn.nvim starts C# itself.
      automatic_enable = { exclude = { "roslyn_ls" } },
    },
  },

  {
    "seblyng/roslyn.nvim",
    -- Not lazy: the plugin enables the server as soon as it loads, so loading
    -- it on the first .cs file would start roslyn before these options apply.
    lazy = false,
    opts = {
      -- Let roslyn watch the solution's files itself. Neovim's watcher doesn't
      -- reliably report changes made outside the editor on Windows (e.g. by
      -- Claude or git), which left roslyn with a stale view of the code.
      filewatching = "roslyn",
    },
  },

  -- Makes lua_ls understand the Neovim API while editing this config.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Per-server settings (merged with nvim-lspconfig's defaults).
      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = { analysis = { typeCheckingMode = "standard" } },
        },
      })

      vim.lsp.config("lemminx", {
        settings = {
          xml = {
            -- XAML has no XML schema; don't flag every file for missing one.
            validation = { noGrammar = "ignore" },
          },
        },
      })

      vim.lsp.config("roslyn", {
        settings = {
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
          },
          ["csharp|code_lens"] = { dotnet_enable_references_code_lens = true },
        },
      })

      -- Neovim only re-requests a file's diagnostics when that file changes.
      -- A change in one file (e.g. Claude adding a method to Helper.cs) can
      -- fix or break others (Caller.cs), so refresh all open files when a file
      -- is saved or reloaded from disk, or when you come back to a code window.
      -- (The public refresh path switches to workspace diagnostics for servers
      -- like roslyn and never re-pulls open files, so re-pull each buffer.)
      local last_refresh = 0
      local function refresh_diagnostics()
        local now = vim.uv.now()
        if now - last_refresh < 1000 then
          return
        end
        last_refresh = now
        vim.defer_fn(function() -- give the server a moment to see the change
          for _, client in ipairs(vim.lsp.get_clients({ method = "textDocument/diagnostic" })) do
            for buf in pairs(client.attached_buffers) do
              if vim.api.nvim_buf_is_loaded(buf) then
                pcall(vim.lsp.diagnostic._refresh, buf, client.id)
              end
            end
          end
        end, 500)
      end
      vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost", "FocusGained", "WinEnter", "TermLeave" }, {
        group = vim.api.nvim_create_augroup("user-lsp-refresh-diagnostics", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].buftype == "" or args.event ~= "WinEnter" then
            refresh_diagnostics()
          end
        end,
      })

      vim.diagnostic.config({
        severity_sort = true,
        float = { source = "if_many" },
        underline = { severity = vim.diagnostic.severity.ERROR },
        virtual_text = { source = "if_many", spacing = 2 },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
        },
      })

      -- Keymaps that only exist in buffers with a language server attached.
      -- Neovim already provides: K hover, grn rename, gra code action,
      -- grr references, gri implementation, grt type definition, gO symbols.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = args.buf, desc = "LSP: " .. desc })
          end
          local tb = require("telescope.builtin")

          map("gd", tb.lsp_definitions, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>ss", tb.lsp_document_symbols, "Search document symbols")
          map("<leader>sS", tb.lsp_dynamic_workspace_symbols, "Search workspace symbols")

          if client:supports_method("textDocument/inlayHint", args.buf) then
            map("<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }))
            end, "Toggle inlay hints")
          end

          -- Let basedpyright handle hover in Python; ruff's hover is minimal.
          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })
    end,
  },
}
