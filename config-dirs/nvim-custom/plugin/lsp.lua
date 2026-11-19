vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/zapling/mason-conform.nvim",
})

require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

require("mason-tool-installer").setup({
  ensure_installed = {
    -- lsps
    "gopls",
    "rust-analyzer",
    "ruby-lsp",
    "vtsls",
    "svelte-language-server",
    -- "html",
    "templ",
    "emmet-language-server",
    "hyprls",
    "just-lsp",
    "typescript-language-server",
    -- formatters
    "stylua",
    "gofumpt",
    "biome",
    "erb-formatter",
    -- dap
    "codelldb",
  },
})

require("mason-lspconfig").setup({})

vim.lsp.config("emmet_language_server", {
  init_options = {
    includeLanguages = {
      typescriptreact = "jsx",
      javascriptreact = "jsx",
    },
    showSuggestionsAsSnippets = true,
  },
})

-- Optional: per-server overrides using the new native API
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      telemetry = { enable = false },
    },
  },
})
vim.lsp.config("vtsls", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})

-- ========================
-- Formatting with conform.nvim
-- ========================
local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format", "black" }, -- or just "ruff_format"
    javascript = { "biome", "biome-organize-imports" },
    typescript = { "biome", "biome-organize-imports" },
    javascriptreact = { "biome", "biome-organize-imports" },
    typescriptreact = { "biome", "biome-organize-imports" },
    json = { "biome" },
    html = { "biome" },
    css = { "biome" },
    markdown = { "prettier" },
    go = { "goimports", "gofmt" },
    rust = { "rustfmt" },
    -- Add more as needed
  },

  -- Optional: Default format options
  default_format_opts = {
    lsp_format = "fallback", -- Use LSP formatting if no dedicated formatter
  },

  -- Format on save
  format_on_save = {
    timeout_ms = 1000,
  },
})

-- Optional: Manual formatting keymap
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format code" })

-- ========================
-- Auto-install formatters with Mason
-- ========================
require("mason-conform").setup({
  -- Optional: ignore certain formatters
  -- ignore_install = { "prettier" },
})

-- ========================
-- Optional: nice LSP defaults
-- ========================
vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  float = { border = "rounded", source = "if_many" },
  virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
})

-- Example LspAttach keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()

vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.enable({
  "lua_ls",
  "ruby-lsp",
})

vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<S-LeftMouse>", function()
  local mouse = vim.fn.getmousepos()
  if mouse.winid ~= 0 and vim.api.nvim_win_is_valid(mouse.winid) then
    vim.api.nvim_set_current_win(mouse.winid)
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, math.max(mouse.column - 1, 0) })
  end
  vim.lsp.buf.hover()
end, { desc = "Hover" })
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<C-x>", vim.diagnostic.open_float)
