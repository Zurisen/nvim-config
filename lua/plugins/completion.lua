-- Autocompletion popup fed by the language servers, file paths and snippets.
return {
  "saghen/blink.cmp",
  version = "1.*", -- stable branch; downloads a prebuilt fuzzy matcher
  event = "InsertEnter",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    -- "default": <C-y> accept, <C-n>/<C-p> navigate, <C-space> open, <C-e> close.
    -- Change to "super-tab" if you prefer Tab to accept, like VS Code.
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "lazydev" },
      providers = {
        lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
      },
    },
    signature = { enabled = true },
  },
}
