require("settings.options")
require("settings.keymaps")
require("settings.autocommands")

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require("lazy").setup({
	require("plugins.guess-indent_setup"),
	require("plugins.gitsigns_setup"),
	require("plugins.which-key_setup"),
	require("plugins.telescope_setup"),
	require("plugins.lazydev_setup"),
	require("plugins.lsp_setup"),
	require("plugins.autoformat_setup"),
	require("plugins.autocompletion_setup"),
	require("plugins.theme_setup"),
	require("plugins.highlights_setup"),
	require("plugins.mini_setup"),
	require("plugins.treesitter_setup"),
	require("plugins.autopairs"),
	require("plugins.nvim-dap_setup"),
	require("plugins.42-header_setup"),
	require("plugins.neo-tree"),
}, {
	ui = {
		-- If you are using a Nerd Font: set icons to an empty table which will use the
		-- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
