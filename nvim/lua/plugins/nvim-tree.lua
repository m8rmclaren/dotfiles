return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        local function my_on_attach(bufnr)
            local api = require "nvim-tree.api"

            local function opts(desc)
                return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
            end

            -- default mappings
            api.config.mappings.default_on_attach(bufnr)

            -- custom mappings
            vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent, opts('Up'))
            vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
        end

        -- pass to setup along with your other options
        require("nvim-tree").setup {
            on_attach = my_on_attach,
            git = {
                enable = true,
                ignore = false, -- 👈 This disables filtering gitignored files
            },
        }

        local api = require "nvim-tree.api"

        vim.keymap.set('n', '<leader>to', api.tree.open, { desc = 'Open nvim-tree' })
        vim.keymap.set('n', '<leader>tc', api.tree.close, { desc = 'Close nvim-tree' })
    end
}
