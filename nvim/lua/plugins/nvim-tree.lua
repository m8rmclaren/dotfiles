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
            view = {
                -- Don't equalize other windows when the tree resizes, so a
                -- manually-widened tree doesn't disturb the file window.
                preserve_window_proportions = true,
            },
            git = {
                enable = true,
                ignore = false, -- 👈 This disables filtering gitignored files
            },
        }

        local api = require "nvim-tree.api"

        vim.keymap.set('n', '<leader>to', api.tree.open, { desc = 'Open nvim-tree' })
        vim.keymap.set('n', '<leader>tc', api.tree.close, { desc = 'Close nvim-tree' })

        -- Persist manual resizes of the nvim-tree window. nvim-tree only stores
        -- its width when resized through its own API, so a drag-resize is lost on
        -- the next redraw (e.g. when opening a file), snapping back to the default.
        -- Capture the current width whenever the tree is resized or left, and feed
        -- it back so the chosen width survives across file selections.
        local function persist_tree_width()
            local winid = api.tree.winid()
            if winid == nil or not vim.api.nvim_win_is_valid(winid) then
                return
            end
            local width = vim.api.nvim_win_get_width(winid)
            api.tree.resize({ width = width })
        end

        local group = vim.api.nvim_create_augroup('NvimTreePersistWidth', { clear = true })
        vim.api.nvim_create_autocmd('WinResized', {
            group = group,
            callback = persist_tree_width,
        })
    end
}
