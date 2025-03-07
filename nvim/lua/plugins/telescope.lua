return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
        { 'nvim-lua/plenary.nvim' }
    },
    config = function()
        local builtin = require('telescope.builtin')

        require('telescope').load_extension('harpoon')

        require('telescope').setup {
            extensions = {
                -- Your extension configuration goes here:
                -- extension_name = {
                --   extension_config_key = value,
                -- }
                -- please take a look at the readme of the extension you want to configure
            }
        }

        -- Regular pickers
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Fuzzy find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Fuzzy find in files' })
        vim.keymap.set('n', '<leader>fm', builtin.keymaps, { desc = 'Fuzzy find available key bindings' })
        -- vim.keymap.set('n', '<leader>fb', builtin.current_buffer_fuzzy_find, {})

        -- Vim pickers
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Fuzzy find help tags' })
        vim.keymap.set('n', '<leader>fp', builtin.diagnostics, { desc = 'Fuzzy find diagnostics' })
        vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Fuzzy find available commands' })
        vim.keymap.set('n', '<leader>fjl', builtin.jumplist, { desc = 'Fuzzy find jump list' })

        -- LSP pickers
        vim.keymap.set('n', 'gd', builtin.lsp_definitions, { desc = 'Go to definition' })
        vim.keymap.set('n', '<leader>fr', builtin.lsp_references,
            { desc = 'Fuzzy find references to the value under cursor' })
        vim.keymap.set('n', '<leader>fqf', builtin.quickfix, { desc = 'Fuzzy find quickfix list' })
        vim.keymap.set('n', '<leader>ft', builtin.lsp_type_definitions,
            { desc = 'Fuzzy find type definitions of the variable under cursor' })
    end
}
