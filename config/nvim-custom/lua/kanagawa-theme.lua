local M = {}

-- Personal kanagawa options. plugin/omarchy-theme.lua calls this when the
-- Omarchy colorscheme is a kanagawa variant, then loads that variant.
function M.setup()
  vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" })

  require("kanagawa").setup({
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {
        lotusRed3 = "#E46876",
        samuraiRed = "#E46876",
      },
      theme = {
        wave = {},
        lotus = {},
        dragon = {},
        all = {
          ui = {
            bg_gutter = "none",
          },
        },
      },
    },
    overrides = function()
      return {
        CursorColumn = { bg = "#242424" },
        CursorLine = { bg = "#242424" },
      }
    end,
    theme = "wave",
    background = {
      dark = "wave",
      light = "lotus",
    },
  })
end

return M
