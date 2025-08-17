-- Set up LSP natively --

return {
	{
		vim.lsp.enable("lua_ls"),
		vim.lsp.enable("clangd"),
	},
}
