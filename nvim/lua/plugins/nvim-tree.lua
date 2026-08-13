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

        -- Keep git decorations in sync with out-of-band edits (Claude Code, a
        -- tmux pane, a rebase in another window). nvim-tree only re-runs
        -- `git status` when .git/{HEAD,index,config,FETCH_HEAD} changes, so an
        -- agent rewriting a tracked file leaves the tree showing stale status.
        -- Its directory watchers still catch created/deleted files; only the
        -- status of existing files goes stale.
        local refresh_timer = nil
        local function refresh_tree(full)
            if refresh_timer then
                refresh_timer:stop()
            end
            -- Debounce: an agent editing ten files in a burst should cost one
            -- `git status`, not ten.
            refresh_timer = vim.defer_fn(function()
                refresh_timer = nil
                -- git.reload re-runs status and redraws; tree.reload also
                -- rescans the filesystem, for when files appeared or vanished.
                pcall(full and api.tree.reload or api.git.reload)
            end, 200)
        end

        -- Entry point for the Claude Code hook, which pokes this over nvim's
        -- RPC socket the moment a tool call finishes writing.
        _G.NvimTreeGitRefresh = function()
            refresh_tree(true)
        end
        vim.api.nvim_create_user_command('NvimTreeGitRefresh', _G.NvimTreeGitRefresh,
            { desc = 'Refresh nvim-tree git status after external edits' })

        local refresh_group = vim.api.nvim_create_augroup('NvimTreeExternalRefresh', { clear = true })

        vim.api.nvim_create_autocmd({ 'FocusGained', 'BufWritePost', 'FileChangedShellPost' }, {
            group = refresh_group,
            callback = function()
                refresh_tree(false)
            end,
            desc = 'Refresh nvim-tree git status',
        })

        -- Leaving or closing a terminal is the moment out-of-band edits have
        -- landed and you're looking at the tree again, so rescan fully here.
        vim.api.nvim_create_autocmd({ 'TermLeave', 'TermClose' }, {
            group = refresh_group,
            callback = function()
                refresh_tree(true)
            end,
            desc = 'Refresh nvim-tree after leaving a terminal',
        })
    end
}
