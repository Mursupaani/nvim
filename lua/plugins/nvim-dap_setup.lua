-- Set up nvim-dap--

local last_args = nil

local function get_most_recent_compile()
	-- Run the build system (adjust as needed)
	local out = vim.fn.system({ "make", "re" })
	if vim.v.shell_error ~= 0 then
		vim.notify(out, vim.log.levels.ERROR)
		return nil
	end

	-- Find the most recently modified executable file
	local cwd = vim.fn.getcwd()
	local find_cmd = [[find %s -type f -executable -printf '%%T@ %%p\n' | sort -nr | head -n1 | cut -d' ' -f2-]]
	local find_exe_cmd = string.format(find_cmd, vim.fn.shellescape(cwd))

	local exe = vim.fn.systemlist(find_exe_cmd)[1]

	if not exe or exe == "" then
		vim.notify("No executable found in project directory", vim.log.levels.ERROR)
		return nil
	end
	return exe
end

local function shell_split(input)
	local args = {}
	local i = 1
	while i <= #input do
		-- Skip whitespace
		while i <= #input and input:sub(i, i):match("%s") do
			i = i + 1
		end

		if i > #input then
			break
		end

		local c = input:sub(i, i)
		local arg = ""

		if c == '"' then
			-- Parse quoted string
			i = i + 1
			while i <= #input and input:sub(i, i) ~= '"' do
				arg = arg .. input:sub(i, i)
				i = i + 1
			end
			i = i + 1 -- skip closing quote
		else
			-- Parse unquoted string
			while i <= #input and not input:sub(i, i):match("%s") do
				arg = arg .. input:sub(i, i)
				i = i + 1
			end
		end

		table.insert(args, arg)
	end
	return args
end

local function get_program()
	return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
end

local function get_args()
	if last_args then
		local use_last =
			vim.fn.input(string.format("Use previous arguments: [%s] [y/n]? ", table.concat(last_args, " ")))
		if use_last:lower() == "y" then
			return last_args
		end
	end
	local input = vim.fn.input("Program arguments (space-separated): ")
	if input == "" then
		return {}
	end
	last_args = shell_split(input)
	return last_args
end

return {
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
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = "codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- GDB via OpenDebugAD7 (cpptools)
			dap.adapters.cppdbg = {
				id = "cppdbg",
				type = "executable",
				command = "OpenDebugAD7", -- now in PATH
			}

			-- Process switching functions
			local switch_to_parent = function()
				if not dap.session() then
					vim.notify("No active debug session", vim.log.levels.WARN)
					return
				end
				-- Send GDB command to switch to parent
				dap.session():request("evaluate", {
					expression = "set follow-fork-mode parent",
					frameId = 0,
					context = "repl",
				}, function(err, response)
					if err then
						vim.notify("Error switching to parent: " .. (err.message or "unknown"), vim.log.levels.ERROR)
					else
						vim.notify("Switched to parent process", vim.log.levels.INFO)
					end
				end)
			end

			local switch_to_child = function()
				if not dap.session() then
					vim.notify("No active debug session", vim.log.levels.WARN)
					return
				end
				-- Send GDB command to switch to child
				dap.session():request("evaluate", {
					expression = "set follow-fork-mode child",
					frameId = 0,
					context = "repl",
				}, function(err, response)
					if err then
						vim.notify("Error switching to child: " .. (err.message or "unknown"), vim.log.levels.ERROR)
					else
						vim.notify("Switched to child process", vim.log.levels.INFO)
					end
				end)
			end

			local list_inferiors = function()
				if not dap.session() then
					vim.notify("No active debug session", vim.log.levels.WARN)
					return
				end
				-- Send GDB command to list all inferiors (processes)
				dap.session():request("evaluate", {
					expression = "info inferiors",
					frameId = 0,
					context = "repl",
				}, function(err, response)
					if err then
						vim.notify("Error listing inferiors: " .. (err.message or "unknown"), vim.log.levels.ERROR)
					else
						-- Show the result in a floating window or buffer
						local lines = vim.split(response.result, "\n")
						vim.api.nvim_echo({ { "Inferiors (processes):", "Title" } }, false, {})
						for _, line in ipairs(lines) do
							vim.api.nvim_echo({ { line, "Normal" } }, false, {})
						end
					end
				end)
			end

			local switch_inferior = function()
				if not dap.session() then
					vim.notify("No active debug session", vim.log.levels.WARN)
					return
				end
				local inferior_id = vim.fn.input("Switch to inferior (process) ID: ")
				if inferior_id == "" then
					return
				end
				-- Send GDB command to switch to specific inferior
				dap.session():request("evaluate", {
					expression = "inferior " .. inferior_id,
					frameId = 0,
					context = "repl",
				}, function(err, response)
					if err then
						vim.notify(
							"Error switching to inferior " .. inferior_id .. ": " .. (err.message or "unknown"),
							vim.log.levels.ERROR
						)
					else
						vim.notify("Switched to inferior " .. inferior_id, vim.log.levels.INFO)
					end
				end)
			end

			local attach_to_process = function()
				local pid = tonumber(vim.fn.input("PID to attach: "))
				if not pid then
					vim.notify("Invalid PID", vim.log.levels.ERROR)
					return
				end

				local program = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				if program == "" then
					vim.notify("Program path required", vim.log.levels.ERROR)
					return
				end

				dap.run({
					name = "Attach to PID " .. pid,
					type = "cppdbg",
					request = "attach",
					processId = pid,
					program = program,
					cwd = vim.fn.getcwd(),
					MIMode = "gdb",
					miDebuggerPath = "gdb",
				})
			end

			local attach_to_child_interactive = function()
				-- Get parent process info
				local parent_input = vim.fn.input("Parent PID or process name: ")
				if parent_input == "" then
					vim.notify("Parent PID/name required", vim.log.levels.ERROR)
					return
				end

				local parent_pid
				if parent_input:match("^%d+$") then
					parent_pid = tonumber(parent_input)
				else
					-- Find PID by process name
					local cmd = string.format("pgrep -f '%s' | head -1", parent_input)
					local output = vim.fn.system(cmd)
					parent_pid = tonumber(vim.trim(output))
					if not parent_pid then
						vim.notify("Could not find process: " .. parent_input, vim.log.levels.ERROR)
						return
					end
				end

				-- Get child PIDs
				local child_pids = get_child_pids(parent_pid)
				if #child_pids == 0 then
					vim.notify("No child processes found for PID: " .. parent_pid, vim.log.levels.WARN)
					return
				end

				-- If only one child, attach directly
				if #child_pids == 1 then
					local program = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					if program ~= "" then
						dap.run({
							name = "Attach to child (PID: " .. child_pids[1] .. ")",
							type = "cppdbg",
							request = "attach",
							processId = child_pids[1],
							program = program,
							cwd = vim.fn.getcwd(),
							MIMode = "gdb",
							miDebuggerPath = "gdb",
						})
					end
					return
				end

				-- Multiple children - show selection
				local options = {}
				for i, pid in ipairs(child_pids) do
					local info = get_process_info(pid)
					table.insert(options, string.format("%d. PID %d: %s", i, pid, info))
				end

				vim.ui.select(options, {
					prompt = "Select child process to attach:",
				}, function(choice, idx)
					if choice and idx then
						local selected_pid = child_pids[idx]
						local program = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						if program ~= "" then
							dap.run({
								name = "Attach to child (PID: " .. selected_pid .. ")",
								type = "cppdbg",
								request = "attach",
								processId = selected_pid,
								program = program,
								cwd = vim.fn.getcwd(),
								MIMode = "gdb",
								miDebuggerPath = "gdb",
							})
						end
					end
				end)
			end

			dap.configurations.c = {
				{
					name = "Launch GDB (Most recent compile / Follow parent)",
					type = "cppdbg",
					request = "launch",
					program = get_most_recent_compile,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = "gdb",
					args = get_args,
					setupCommands = {
						-- { text = "set detach-on-fork off", description = "Keep parent alive after fork" },
						{ text = "set follow-fork-mode parent", description = "Stay on parent after fork" },
						{ text = "set pagination off", description = "Disable GDB pagination" },
						{
							text = "set non-stop on",
							description = "Enable non-stop mode for multi-process debugging",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Launch GDB (Most recent compile / Follow child)",
					type = "cppdbg",
					request = "launch",
					program = get_most_recent_compile,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = "gdb",
					args = get_args,
					setupCommands = {
						{ text = "set detach-on-fork off", description = "Keep parent alive after fork" },
						{ text = "set follow-fork-mode child", description = "Follow child after fork" },
						{ text = "set pagination off", description = "Disable GDB pagination" },
						{
							text = "set non-stop on",
							description = "Enable non-stop mode for multi-process debugging",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Launch GDB (Follow parent)",
					type = "cppdbg",
					request = "launch",
					program = get_program,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = "gdb",
					args = get_args,
					setupCommands = {
						{ text = "set detach-on-fork off", description = "Keep parent alive after fork" },
						{ text = "set follow-fork-mode parent", description = "Stay on parent after fork" },
						{ text = "set pagination off", description = "Disable GDB pagination" },
						{
							text = "set non-stop on",
							description = "Enable non-stop mode for multi-process debugging",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Launch GDB (Follow child)",
					type = "cppdbg",
					request = "launch",
					program = get_program,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
					MIMode = "gdb",
					miDebuggerPath = "gdb",
					args = get_args,
					setupCommands = {
						{ text = "set detach-on-fork off", description = "Keep parent alive after fork" },
						{ text = "set follow-fork-mode child", description = "Follow child after fork" },
						{ text = "set pagination off", description = "Disable GDB pagination" },
						{
							text = "set non-stop on",
							description = "Enable non-stop mode for multi-process debugging",
							ignoreFailures = true,
						},
					},
				},
				{
					name = "Attach to Process (GDB)",
					type = "cppdbg",
					request = "attach",
					processId = function()
						return tonumber(vim.fn.input("PID: "))
					end,
					program = get_program,
					MIMode = "gdb",
					miDebuggerPath = "gdb",
					cwd = "${workspaceFolder}",
				},
				{
					name = "Launch LLDB",
					type = "codelldb",
					request = "launch",
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					program = get_program,
					args = get_args,
				},
			}
			dap.configurations.cpp = dap.configurations.c

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

			-- Basic keymaps
			vim.keymap.set("n", "<space>ds", dap.continue, { desc = "[D]ebug [S]tart session" })
			vim.keymap.set("n", "<space>db", dap.toggle_breakpoint, { desc = "[D]ebug toggle [B]reakpoint" })
			vim.keymap.set("n", "<space>dr", dap.run_to_cursor, { desc = "[D]ebug [R]un to cursor" })
			vim.keymap.set("n", "<leader>dq", function()
				dap.terminate()
				ui.close()
			end, { desc = "[D]ebug [Q]uit DAP session" })
			vim.keymap.set("n", "<space>dc", function()
				require("dap").clear_breakpoints()
			end, { desc = "[D]ebug [C]lear all breakpoints" })

			-- Process switching keymaps
			vim.keymap.set("n", "<leader>dp", switch_to_parent, { desc = "[D]ebug switch to [P]arent process" })
			vim.keymap.set("n", "<leader>dC", switch_to_child, { desc = "[D]ebug switch to [C]hild process" })
			vim.keymap.set("n", "<leader>dl", list_inferiors, { desc = "[D]ebug [L]ist inferiors (processes)" })
			vim.keymap.set("n", "<leader>di", switch_inferior, { desc = "[D]ebug switch [I]nferior" })
			vim.keymap.set("n", "<leader>da", attach_to_process, { desc = "[D]ebug [A]ttach to process" })
			vim.keymap.set(
				"n",
				"<leader>dA",
				attach_to_child_interactive,
				{ desc = "[D]ebug [A]ttach to child (interactive)" }
			)

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
				virtual_text.enable()
			end
			dap.listeners.before.launch.dapui_config = function()
				ui.open()
				virtual_text.enable()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				ui.close()
				virtual_text.disable()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				ui.close()
				virtual_text.disable()
			end
		end,
	},
	-- {
	-- 	"julianolf/nvim-dap-lldb",
	--
	-- 	dependencies = { "mfussenegger/nvim-dap" },
	-- 	opts = { codelldb_path = "codelldb" },
	-- 	config = function()
	-- 		local cfg = {
	-- 			configurations = {
	-- 				-- C lang configurations
	-- 				c = {
	-- 					{
	-- 						name = "Launch LLDB",
	-- 						type = "codelldb",
	-- 						request = "launch",
	-- 						cwd = "${workspaceFolder}",
	-- 						stopOnEntry = false,
	-- 						-- NOTE: MAC setup:
	-- 						-- program = function()
	-- 						-- 	-- Build with debug symbols
	-- 						-- 	-- local out = vim.fn.system({ "make", "debug" })
	-- 						-- 	local out = vim.fn.system({ "make", "re" })
	-- 						-- 	-- Check for errors
	-- 						-- 	if vim.v.shell_error ~= 0 then
	-- 						-- 		vim.notify(out, vim.log.levels.ERROR)
	-- 						-- 		return nil
	-- 						-- 	end
	-- 						-- 	-- Return path to the debuggable program
	-- 						-- 	return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
	-- 						-- 	-- return "path/to/executable"
	-- 						-- end,
	-- 						-- -- NOTE: MAC setup ^^
	-- 						--
	-- 						-- NOTE: LINUX setup:
	-- 						program = function()
	-- 							-- Run the build system (adjust as needed)
	-- 							local out = vim.fn.system({ "make", "re" })
	-- 							if vim.v.shell_error ~= 0 then
	-- 								vim.notify(out, vim.log.levels.ERROR)
	-- 								return nil
	-- 							end
	--
	-- 							-- Find the most recently modified executable file
	-- 							local cwd = vim.fn.getcwd()
	-- 							local find_cmd =
	-- 								[[find %s -type f -executable -printf '%%T@ %%p\n' | sort -nr | head -n1 | cut -d' ' -f2-]]
	-- 							local find_exe_cmd = string.format(find_cmd, vim.fn.shellescape(cwd))
	--
	-- 							local exe = vim.fn.systemlist(find_exe_cmd)[1]
	--
	-- 							if not exe or exe == "" then
	-- 								vim.notify("No executable found in project directory", vim.log.levels.ERROR)
	-- 								return nil
	-- 							end
	--
	-- 							return exe
	-- 						end,
	-- 						-- NOTE: LINUX setup ^^
	-- 						args = get_args,
	-- 					},
	-- 				},
	-- 			},
	-- 		}
	-- 		require("dap-lldb").setup(cfg)
	-- 	end,
	-- },
}
