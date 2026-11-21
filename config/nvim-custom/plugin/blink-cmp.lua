vim.pack.add({ "https://github.com/saghen/blink.lib", "https://github.com/saghen/blink.cmp" })
local cmp = require("blink.cmp")
cmp.build():wait(60000)
-- cmp.setup()

local function min_keyword_length(normal)
  return function(ctx)
    return ctx.trigger.initial_kind == "manual" and 0 or normal
  end
end

cmp.setup({
  -- 'default' for standard Vim-style completion
  -- 'super-tab' for VSCode-like Tab/Shift-Tab completion behaviors
  -- keymap = { preset = "super-tab" },blink
  keymap = {
    preset = "enter",
  },

  completion = {
    list = {
      selection = { preselect = true, auto_insert = false },
    },
  },

  snippets = { preset = "default" },

  appearance = {
    -- Fallback to nvim-cmp's highlight groups if your theme doesn't support blink yet
    use_nvim_cmp_as_default = true,
    nerd_font_variant = "mono",
  },

  -- Sources to pull suggestions from
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp = { min_keyword_length = min_keyword_length(1) },
      snippets = { min_keyword_length = min_keyword_length(1) },
      buffer = { min_keyword_length = min_keyword_length(2) },
      path = { min_keyword_length = min_keyword_length(1) },
    },
  },
})
