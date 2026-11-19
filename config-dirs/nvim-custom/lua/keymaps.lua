-- Diffview
vim.keymap.set("n", "<leader>a", "<cmd>Alpha<cr>")
vim.keymap.set(
  "n",
  "<leader>df",
  "<cmd>DiffviewFileHistory %<cr>",
  { desc = "Diffview Current File History", silent = true }
)
vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview History", silent = true })
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close", silent = true })
vim.keymap.set("n", "<leader>dl", "<cmd>DiffviewLog<cr>", { desc = "Diffview Log", silent = true })
vim.keymap.set("n", "<leader>do", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open", silent = true })

vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy.nvim", silent = true })

-- -- Escape terminal
vim.keymap.set("t", "<C-j>", "<C-\\><C-n>")
-- -- Turn of search highlight
vim.keymap.set("n", "<esc>", "<cmd>noh<cr>")

vim.keymap.set("n", "<leader>w", "<cmd>set wrap!<cr>")

-- Based on the primagen's video https://www.youtube.com/watch?v=w7i4amO_zaE&t=9s
-- keep cursor position when using J
-- vim.keymap.set("v", "J", ":m '>+1<cr>gv=gv")
-- vim.keymap.set("v", "K", ":m '<-2<cr>gv=gv")
-- vim.keymap.set("n", "J", "mzJ`z")

-- keep cursor in middle of screen for scrolling
-- vim.keymap.set("n", "<c-d>", "<c-d>zz")
-- vim.keymap.set("n", "<c-u>", "<c-u>zz")
-- keep cursor in middle of screen when searching
-- vim.keymap.set("n", "n", "nzzzv")
-- vim.keymap.set("n", "N", "Nzzzv")

-- copy/paste
vim.keymap.set("n", "<leader>p", '"+p')
vim.keymap.set("v", "<leader>p", '"+p')
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<C-S-j>", "<cmd>resize -4<cr>")
vim.keymap.set("n", "<C-S-k>", "<cmd>resize +4<cr>")
vim.keymap.set("n", "<C-S-h>", "<cmd>vertical resize +4<cr>")
vim.keymap.set("n", "<C-S-l>", "<cmd>vertical resize -4<cr>")
vim.keymap.set("n", "<C-S-=>", "<cmd>wincmd =<cr>")
vim.keymap.set({ "n", "i", "x" }, "<C-s>", "<cmd>write<cr>", { desc = "Write" })
