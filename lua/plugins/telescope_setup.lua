-- Set up telescope --

return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        pickers = {
          buffers = {
            mappings = {
              n = {
                -- Delete buffers with dd in telescope picker
                ['dd'] = function(prompt_bufnr)
                  local action_state = require 'telescope.actions.state'
                  local bufremove = require 'mini.bufremove'
                  local picker = action_state.get_current_picker(prompt_bufnr)
                  local entry = action_state.get_selected_entry()
                  local bufnr = entry.bufnr
                  if entry and bufnr then
                    local is_modified = vim.bo[entry.bufnr].modified
                    local bufname = vim.api.nvim_buf_get_name(bufnr)
                    local filename = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t') or '[No Name]'

                    if is_modified then
                      local choice = vim.fn.confirm(string.format('Save changes to "%s"?', filename), '&Yes\n&No\n&Cancel', 3)
                      if choice == 1 then
                        vim.api.nvim_buf_call(bufnr, function()
                          vim.cmd 'silent! write'
                        end)
                      elseif choice == 3 then
                        return
                      end
                    end
                    bufremove.delete(entry.bufnr, true) -- force delete
                    picker:refresh()
                    vim.cmd [[Telescope buffers sort_mru=true sort_lastused=true initial_mode=normal theme=ivy]]
                  end
                end,
              },
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }
      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sa', function()
        local home_dir = vim.fn.expand '$HOME/Projects'
        builtin.find_files {
          cwd = home_dir,
          previewer = false,
        }
      end, { desc = '[S]earch [A]ll files /' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set(
        'n',
        '<leader><leader>',
        '<cmd>Telescope buffers sort_mru=true sort_lastused=true initial_mode=insert theme=ivy<cr>',
        { desc = '[ ] Find existing buffers' }
      )

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
