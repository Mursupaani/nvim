-- Set up LSP --

return {
	{
		vim.lsp.enable('clangd')

		vim.api.nvim_create_autocmd('Lsp')
	},
}
