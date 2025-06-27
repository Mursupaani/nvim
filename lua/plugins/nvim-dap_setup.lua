-- Set up nvim-dap--

local last_args = nil

return {
	{
		"mfussenegger/nvim-dap",
	},
	{
		{
			"mfussenegger/nvim-dap",
			dependencies = {
				"leoluz/nvim-dap-go",
				"rcarriga/nvim-dap-ui",
				"theHamsta/nvim-dap-virtual-text",
				"nvim-neotest/nvim-nio",
				"williamboman/mason.nvim",
			},
			config = function()
				local dap = require("dap")
				local ui = require("dapui")
				local virtual_text = require("nvim-dap-virtual-text")

				require("dapui").setup()
				virtual_text.setup({
					enabled = true,
					enable_commands = true,
					highlight_changed_variables = true,
					highlight_new_as_changed = true,
					show_stop_reason = true,
					commented = false,
					only_first_definition = true,
					all_references = true,
					all_frames = true,
					clear_on_continue = false,
					text_prefix = " ", -- Nerd Font symbol, change if needed
					separator = " │ ",
					error_prefix = " ", -- Or "✗"
					info_prefix = " ", -- Or "ℹ️"
					virt_text_pos = "eol", -- or 'overlay', 'right_align'
					virt_lines = false,
					virt_lines_above = false,
					filter_references_pattern = "nil",
					display_callback = function(variable)
						-- For LLDB, we can usually assume name/value is enough
						return string.format("%s = %s", variable.name, variable.value)
					end,
				})

				require("dap-go").setup()
				--debug C with lldb
				require("dap").adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = {
						command = "codelldb",
						args = { "--port", "${port}" },
					},
				}

				local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
				if elixir_ls_debugger ~= "" then
					dap.adapters.mix_task = {
						type = "executable",
						command = elixir_ls_debugger,
					}

					dap.configurations.elixir = {
						{
							type = "mix_task",
							name = "phoenix server",
							task = "phx.server",
							request = "launch",
							projectDir = "${workspaceFolder}",
							exitAfterTaskReturns = false,
							debugAutoInterpretAllModules = false,
						},
					}
				end

				vim.keymap.set("n", "<space>ds", dap.continue, { desc = "[D]ebug [S]tart session" })
				vim.keymap.set("n", "<space>db", dap.toggle_breakpoint, { desc = "[D]ebug toggle [B]reakpoint" })
				vim.keymap.set("n", "<space>dr", dap.run_to_cursor, { desc = "[D]ebug [R]un to cursor" })
				vim.keymap.set("n", "<leader>dq", function()
					dap.terminate()
					ui.close()
					virtual_text.disable()
				end, { desc = "[D]ebug [Q]uit DAP session" })
				vim.keymap.set("n", "<space>dc", function()
					require("dap").clear_breakpoints()
				end, { desc = "[D]ebug [C]lear all breakpoints" })

				-- Eval var under cursor
				vim.keymap.set("n", "<leader>dv", function()
					ui.eval(nil, {
						context = "hover",
						-- width = 1,
						-- height = 1,
						enter = false,
					})
				end, { desc = "[D]ebug evaluate [V]ariable under cursor" })

				vim.keymap.set("n", "<F6>", dap.continue)
				vim.keymap.set("n", "<F7>", dap.step_into)
				vim.keymap.set("n", "<F8>", dap.step_over)
				vim.keymap.set("n", "<F9>", dap.step_out)
				vim.keymap.set("n", "<F10>", dap.step_back)
				vim.keymap.set("n", "<F11>", dap.restart)

				dap.listeners.before.attach.dapui_config = function()
					ui.open()
				end
				dap.listeners.before.launch.dapui_config = function()
					ui.open()
				end
				dap.listeners.before.event_terminated.dapui_config = function()
					ui.close()
				end
				dap.listeners.before.event_exited.dapui_config = function()
					ui.close()
				end
			end,
		},
	},
	{
		"julianolf/nvim-dap-lldb",

		dependencies = { "mfussenegger/nvim-dap" },
		opts = { codelldb_path = "/path/to/codelldb" },
		config = function()
			local cfg = {
				configurations = {
					-- C lang configurations
					c = {
						{
							name = "Launch debugger",
							type = "lldb",
							request = "launch",
							cwd = "${workspaceFolder}",
							stopOnEntry = false,
							-- NOTE: MAC setup:
							-- program = function()
							--   -- Build with debug symbols
							--   -- local out = vim.fn.system({ "make", "debug" })
							--   local out = vim.fn.system { 'make', 're' }
							--   -- Check for errors
							--   if vim.v.shell_error ~= 0 then
							--     vim.notify(out, vim.log.levels.ERROR)
							--     return nil
							--   end
							--   -- Return path to the debuggable program
							--   return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
							--   -- return "path/to/executable"
							-- end,
							-- NOTE: MAC setup ^^

							program = function()
								local cwd = vim.fn.getcwd()

								-- Step 1: Build
								local out = vim.fn.system({ "make", "re" })
								if vim.v.shell_error ~= 0 then
									vim.notify(out, vim.log.levels.ERROR)
									return nil
								end

								-- Step 2: Try to find an executable (file command must say ELF)
								local scan_cmd =
									[[find "%s" -type f -executable -exec file {} \; | grep -i 'ELF' | cut -d: -f1 | head -n1]]
								local cmd = string.format(scan_cmd, cwd)
								local handle = io.popen(cmd)
								if not handle then
									vim.notify("Failed to scan for executables", vim.log.levels.ERROR)
									return nil
								end

								local exe = handle:read("*l")
								handle:close()

								if not exe or exe == "" then
									vim.notify("No valid ELF executable found in workspace", vim.log.levels.ERROR)
									return nil
								end

								return exe
							end,

							args = function()
								if last_args then
									local use_last = vim.fn.input(
										string.format(
											"Use previous arguments: [%s] [y/n]? ",
											table.concat(last_args, " ")
										)
									)
									if use_last:lower() == "y" then
										return last_args
									end
								end
								local input = vim.fn.input("Program arguments (space-separated): ")
								if input == "" then
									return {}
								end
								last_args = vim.fn.split(input, " ", true)
								return last_args
							end,
							setupCommands = {
								{
									text = "breakpoint set --name main",
									description = "Set breakpoint at main",
									ignoreFailures = false,
								},
							},
						},
					},
				},
			}

			require("dap-lldb").setup(cfg)
		end,
	},
}
