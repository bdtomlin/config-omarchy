vim.pack.add({ "https://github.com/lukas-reineke/indent-blankline.nvim" })

local function indent_highlights()
  vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3B3B3B" })
  vim.api.nvim_set_hl(0, "IblScope", { fg = "#875F5F" })
end

indent_highlights()

require("ibl").setup({
  indent = { char = "▏" },
  scope = {
    show_start = false,
    show_end = false,
  }
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("IndentlineHl", { clear = true }),
  callback = indent_highlights,
})

