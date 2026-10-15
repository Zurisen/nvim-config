-- Syntax highlighting and indentation via Tree-sitter.
-- Requires the tree-sitter CLI and a C compiler (MSVC from Visual Studio is used).
local parsers = {
  "c_sharp",
  "python",
  "typescript", "tsx", "javascript",
  "json", "yaml", "toml", "xml", "html", "css",
  "lua", "vim", "vimdoc", "query",
  "markdown", "markdown_inline",
  "bash", "powershell",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- this plugin does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
      callback = function(args)
        -- Only start if a parser exists for this filetype.
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
