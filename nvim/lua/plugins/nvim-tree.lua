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

        local views = require("tree-views")

        -- pass to setup along with your other options
        require("nvim-tree").setup {
            on_attach = my_on_attach,
            -- Expand the tree to whatever file you land on, so jumping via
            -- Telescope leaves the tree pointed at that file instead of wherever
            -- it was last.
            update_focused_file = {
                enable = true,
                -- Leave the tree root alone; only change it manually via <C-t>
                -- / :NvimTreeFindFile. Set to true to have the root follow files
                -- opened outside the current root.
                update_root = false,
            },
            view = {
                -- Don't equalize other windows when the tree resizes, so a
                -- manually-widened tree doesn't disturb the file window.
                preserve_window_proportions = true,
            },
            renderer = {
                -- Name the active view in the tree header, so it's obvious
                -- which slice of the repo you're looking at.
                root_folder_label = views.root_label,
            },
            filters = {
                -- nvim-tree accepts a function here and calls it per path.
                -- Dispatching through tree-views means switching views is just
                -- swapping a table, with no second setup() call.
                custom = views.filter,
            },
            git = {
                enable = true,
                ignore = false, -- 👈 This disables filtering gitignored files
            },
        }

        local api = require "nvim-tree.api"

        vim.keymap.set('n', '<leader>to', api.tree.open, { desc = 'Open nvim-tree' })
        vim.keymap.set('n', '<leader>tc', api.tree.close, { desc = 'Close nvim-tree' })

        -- Named views into a codebase: :TreeView <name>, or <leader>tv to pick.
        --
        -- The global views live in lua/tree-views/views.lua. A project's own come
        -- from `.nvim/tree-views.lua` in its main checkout and are merged in when
        -- nvim starts inside it, so the roots follow you into a git worktree
        -- instead of pointing at wherever the definition was written.
        views.setup {
            global = require("tree-views.views"),
            -- Picker order for the global groups. The current project's own
            -- groups sort ahead of these; anything unlisted falls in
            -- alphabetically behind.
            groups = { "editor" },
        }
        vim.keymap.set('n', '<leader>tv', views.pick, { desc = 'Pick nvim-tree view' })
        vim.keymap.set('n', '<leader>tV', views.clear, { desc = 'Clear nvim-tree view' })

        -- Persist manual resizes of the nvim-tree window. nvim-tree only stores
        -- its width when resized through its own API, so a drag-resize is lost on
        -- the next redraw (e.g. when opening a file), snapping back to the default.
        -- Capture the current width whenever the tree is resized and feed it back
        -- so the chosen width survives across file selections.
        --
        -- api.tree.resize() does not merely resize the window: view.resize() writes
        -- the value into nvim-tree's stored View.width, which it later restores the
        -- tree to after opening a file. So anything we hand it becomes the tree's
        -- width forever, and sampling a transient or degenerate width poisons it.
        -- Two such states have to be filtered out:
        --
        --   * The tree is the only window in the tab -- `nvim .` hijacks the
        --     directory buffer, so before the first file is opened the tree spans
        --     every column. Persisting that makes nvim-tree "restore" a full-width
        --     tree afterwards, pinning the file window against the right edge.
        --   * Mid-operation widths. nvim-tree opens a file by running `vsplit`
        --     first and only then calling view.resize(); WinResized fires inside
        --     that gap with the tree at an even 50% split. Deferring the sample to
        --     vim.schedule() lets the whole sequence settle, so we read the width
        --     nvim-tree actually settled on rather than the halfway state.
        local MIN_TREE_WIDTH = 10
        local persisting = false

        local function tree_shares_the_tab(winid)
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                -- Floating windows (completion, notifications) don't take columns
                -- away from the tree, so they don't make its width meaningful.
                if win ~= winid and vim.api.nvim_win_get_config(win).relative == '' then
                    return true
                end
            end
            return false
        end

        local function persist_tree_width()
            if persisting then
                return
            end

            local winid = api.tree.winid()
            if winid == nil or not vim.api.nvim_win_is_valid(winid) then
                return
            end

            -- Only react when the tree itself changed size; resizing the file
            -- window shouldn't re-announce the tree's width.
            local resized = vim.v.event.windows
            if resized and not vim.tbl_contains(resized, winid) then
                return
            end

            persisting = true
            vim.schedule(function()
                persisting = false

                local win = api.tree.winid()
                if win == nil or not vim.api.nvim_win_is_valid(win) or not tree_shares_the_tab(win) then
                    return
                end

                local width = vim.api.nvim_win_get_width(win)
                -- A tree wide enough to leave no room for a file is never what was
                -- meant, however the window got that way.
                if width < MIN_TREE_WIDTH or width > vim.o.columns - MIN_TREE_WIDTH then
                    return
                end

                pcall(api.tree.resize, { width = width })
            end)
        end

        local group = vim.api.nvim_create_augroup('NvimTreePersistWidth', { clear = true })
        vim.api.nvim_create_autocmd('WinResized', {
            group = group,
            callback = persist_tree_width,
            desc = 'Remember a manually resized nvim-tree width',
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
