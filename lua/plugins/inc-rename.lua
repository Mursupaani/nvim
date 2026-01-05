return {
	{
		"smjonas/inc-rename.nvim",
		opts = {
			vim.keymap.set("n", "<leader>ra", ":IncRename ", { desc = "[R]ename [A]ll" }),
			vim.keymap.set("n", "<leader>rr", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true, desc = "[R]ename [R]eplace" }),
		},
	},
}
