-- Neogen annotation
-- Create annotations with one keybind, and jump your cursor in the inserted annotation
-- Defaults for multiple languages and annotation conventions
-- Extremely customizable and extensible
-- Written in lua (and uses Tree-sitter)

return {
	{
		"danymat/neogen",
		config = true,
		-- Uncomment next line if you want to follow only stable versions
		-- version = "*"
		-- vim.api.nvim_set_keymap("n", "<Leader>nf", ":lua require('neogen').generate()<CR>", opts),
		vim.keymap.set(
			"n",
			"<Leader>nf",
			":lua require('neogen').generate()<CR>",
			{ desc = "Documentation for [F]unction" }
		),
		vim.keymap.set(
			"n",
			"<Leader>nc",
			":lua require('neogen').generate({ type = 'class' })<CR>",
			{ desc = "Documentation for [C]lass" }
		),
	},
}
