-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Map keys
--
-- Force Tab to insert a tab character (or spaces) and ignore snippet jumps
vim.keymap.set("i", "<Tab>", "<Tab>", { noremap = true })

vim.keymap.set(
	"n",
	"<C-c>",
	"<Nop>",
	{ noremap = true, silent = true, desc = "Prevent quitting on Ctrl-C during debug" }
)
vim.keymap.set("v", "§", "q")
vim.keymap.set("n", "§", "q")
vim.keymap.set("n", "q", "")
vim.keymap.set("v", "q", "")
vim.keymap.set("v", "j", "gj")
vim.keymap.set("v", "k", "gk")
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("i", "qq", "<Esc>")
vim.keymap.set("v", "qq", "<Esc>")
vim.keymap.set("n", "qq", "<Esc>")
vim.keymap.set("i", "QQ", "<Esc>")
vim.keymap.set("v", "QQ", "<Esc>")
vim.keymap.set("n", "QQ", "<Esc>")
vim.keymap.set("i", ";;", "<Esc>")
vim.keymap.set("v", ";;", "<Esc>")
vim.keymap.set("n", ";;", "<Esc>")
vim.keymap.set("n", "<M-n>", "<Left>")
vim.keymap.set("n", "<M-i>", "<Right>")
vim.keymap.set("n", "<M-u>", "<Up>")
vim.keymap.set("n", "<M-e>", "<Down>")
vim.keymap.set("i", "<M-n>", "<Left>")
vim.keymap.set("i", "<M-i>", "<Right>")
vim.keymap.set("i", "<M-u>", "<Up>")
vim.keymap.set("i", "<M-e>", "<Down>")

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "qq", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", ";;", "<cmd>nohlsearch<CR>")

-- Show manual
vim.keymap.set("n", "<Leader>m", "K", { desc = "Open terminal [M]anual page" })

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>l", vim.diagnostic.setloclist, { desc = "Open diagnostic quickfix [L]ist" })

-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

--  Use CTRL+<hjkl> to switch between windows
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Set snippet jumps
vim.keymap.set("i", "<C-h>", function()
	if vim.snippet.active({ direction = 1 }) then
		vim.snippet.jump(1)
	else
		return "<C-j>"
	end
end, { expr = true, silent = true })

vim.keymap.set("i", "<C-l>", function()
	if vim.snippet.active({ direction = -1 }) then
		vim.snippet.jump(-1)
	else
		return "<C-k>"
	end
end, { expr = true, silent = true })
