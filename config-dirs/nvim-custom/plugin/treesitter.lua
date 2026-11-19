-- lua/plugins/treesitter.lua
-- Requires Neovim 0.12+ and tree-sitter-cli on PATH (system package, not npm).

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
})

require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

local parsers = {
  -- Neovim / config
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query",
  -- JS / TS / React
  "javascript",
  "typescript",
  "tsx",
  "jsdoc",
  "html",
  "css",
  "scss",
  -- web / data
  "json",
  "yaml",
  "toml",
  "markdown",
  "markdown_inline",
  "regex",
  "graphql",
  "svelte",
  -- systems / other langs you use
  "bash",
  "rust",
  "ruby",
  "go",
  "python",
  -- git / misc
  "gitcommit",
  "gitignore",
  "git_rebase",
  "diff",
  "comment",
  "dockerfile",
  "sql",
}

require("nvim-treesitter").install(parsers)

-- Filetype → parser. This is the usual React highlighting miss.
vim.treesitter.language.register("tsx", { "typescriptreact" })
vim.treesitter.language.register("javascript", { "javascriptreact" })

local filetypes = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "html",
  "css",
  "scss",
  "json",
  "yaml",
  "toml",
  "markdown",
  "bash",
  "sh",
  "zsh",
  "rust",
  "ruby",
  "go",
  "python",
  "gitcommit",
  "gitignore",
  "diff",
  "dockerfile",
  "sql",
  "svelte",
  "graphql",
}

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
  pattern = filetypes,
  callback = function(ev)
    local ok = pcall(vim.treesitter.start)
    if not ok then
      return
    end

    -- Highlight
    vim.bo[ev.buf].syntax = "off"

    -- Folds (window-local, current window only)
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldlevel = 99

    -- Room for sticky scope lines. The context window will not cover the cursor,
    -- so a cursor sitting on the top row leaves it nothing to draw.
    vim.wo[0][0].scrolloff = 5

    -- Indent (experimental; skip lua if it fights your formatter)
    if vim.bo[ev.buf].filetype ~= "lua" then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = "TreesitterSetup",
  callback = function(ev)
    if vim.tbl_contains(filetypes, vim.bo[ev.buf].filetype) then
      vim.wo.scrolloff = 5
    end
  end,
})

-- JSX queries capture PascalCase components as @tag and HTML tags as @tag.builtin.
-- htmlTag/htmlArg are unset in kanagawa, so linking to them cleared these colors.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("TreesitterReactHl", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "@type.tsx", { link = "Type" })
    vim.api.nvim_set_hl(0, "@tag.tsx", { link = "Type" })
    vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { link = "Tag" })
    vim.api.nvim_set_hl(0, "@tag.attribute.tsx", { link = "@tag.attribute" })
    vim.api.nvim_set_hl(0, "@tag.delimiter.tsx", { link = "@tag.delimiter" })

    vim.api.nvim_set_hl(0, "@tag.javascript", { link = "Type" })
    vim.api.nvim_set_hl(0, "@tag.builtin.javascript", { link = "Tag" })
    vim.api.nvim_set_hl(0, "@tag.attribute.javascript", { link = "@tag.attribute" })
    vim.api.nvim_set_hl(0, "@tag.delimiter.javascript", { link = "@tag.delimiter" })

    local line_nr = vim.api.nvim_get_hl(0, { name = "LineNr", link = false })
    vim.api.nvim_set_hl(0, "TreesitterContext", { link = "Normal" })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "TreesitterContextBottom", {
      underline = true,
      sp = line_nr.fg or "Grey",
    })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumberBottom", { link = "TreesitterContextBottom" })
  end,
})
vim.api.nvim_exec_autocmds("ColorScheme", { group = "TreesitterReactHl" })

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
    selection_modes = {
      ["@parameter.outer"] = "v",
      ["@function.outer"] = "V",
      ["@class.outer"] = "V",
    },
    include_surrounding_whitespace = false,
  },
  move = { set_jumps = true },
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")
local swap = require("nvim-treesitter-textobjects.swap")

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

map({ "x", "o" }, "af", function()
  select.select_textobject("@function.outer", "textobjects")
end, "Select outer function")
map({ "x", "o" }, "if", function()
  select.select_textobject("@function.inner", "textobjects")
end, "Select inner function")
map({ "x", "o" }, "ac", function()
  select.select_textobject("@class.outer", "textobjects")
end, "Select outer class")
map({ "x", "o" }, "ic", function()
  select.select_textobject("@class.inner", "textobjects")
end, "Select inner class")
map({ "x", "o" }, "aa", function()
  select.select_textobject("@parameter.outer", "textobjects")
end, "Select outer parameter")
map({ "x", "o" }, "ia", function()
  select.select_textobject("@parameter.inner", "textobjects")
end, "Select inner parameter")

map({ "n", "x", "o" }, "]f", function()
  move.goto_next_start("@function.outer", "textobjects")
end, "Next function start")
map({ "n", "x", "o" }, "[f", function()
  move.goto_previous_start("@function.outer", "textobjects")
end, "Prev function start")
map({ "n", "x", "o" }, "]c", function()
  move.goto_next_start("@class.outer", "textobjects")
end, "Next class start")
map({ "n", "x", "o" }, "[c", function()
  move.goto_previous_start("@class.outer", "textobjects")
end, "Prev class start")

map("n", "<leader>a", function()
  swap.swap_next("@parameter.inner")
end, "Swap next parameter")
map("n", "<leader>A", function()
  swap.swap_previous("@parameter.inner")
end, "Swap prev parameter")

-- VS Code sticky scroll: enabled, maxLineCount 5, follow the viewport.
-- Keep outer scopes (function, class) when the stack is taller than 5.
require("treesitter-context").setup({
  enable = true,
  max_lines = 5,
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 20,
  trim_scope = "inner",
  mode = "topline",
  separator = nil,
})
