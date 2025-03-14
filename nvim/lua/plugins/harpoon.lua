return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "nvim-telescope/telescope.nvim" }
    },
    config = function()
        local action_state = require("telescope.actions.state")
        local action_utils = require("telescope.actions.utils")
        local entry_display = require("telescope.pickers.entry_display")
        local finders = require("telescope.finders")
        local pickers = require("telescope.pickers")
        local conf = require("telescope.config").values
        local harpoon = require("harpoon")

        harpoon:setup()

        local function filter_empty_string(list)
            local next = {}
            for idx = 1, #list do
                if list[idx] ~= nil and list[idx].value ~= nil and list[idx].value ~= "" then
                    table.insert(next, list[idx])
                end
            end

            return next
        end

        local generate_new_finder = function()
            return finders.new_table({
                results = filter_empty_string(harpoon:list().items),
                entry_maker = function(entry)
                    local line = entry.value
                        .. ":"
                        .. entry.context.row
                        .. ":"
                        .. entry.context.col
                    local displayer = entry_display.create({
                        separator = " - ",
                        items = {
                            { width = 2 },
                            { width = 50 },
                            { remaining = true },
                        },
                    })
                    local make_display = function()
                        return displayer({
                            tostring(entry.index),
                            line,
                        })
                    end
                    return {
                        value = entry,
                        ordinal = line,
                        display = make_display,
                        lnum = entry.row,
                        col = entry.col,
                        filename = entry.value,
                    }
                end,
            })
        end

        local delete_harpoon_mark = function(prompt_bufnr)
            local confirmation = vim.fn.input(string.format("Delete current mark(s)? [y/n]: "))
            if
                string.len(confirmation) == 0
                or string.sub(string.lower(confirmation), 0, 1) ~= "y"
            then
                print(string.format("Didn't delete mark"))
                return
            end

            local selection = action_state.get_selected_entry()
            harpoon:list():remove(selection.value)

            local function get_selections()
                local results = {}
                action_utils.map_selections(prompt_bufnr, function(entry)
                    table.insert(results, entry)
                end)
                return results
            end

            local selections = get_selections()
            for _, current_selection in ipairs(selections) do
                harpoon:list():remove(current_selection.value)
            end

            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:refresh(generate_new_finder(), { reset_prompt = true })
        end

        local move_mark_up = function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local length = harpoon:list():length()

            if selection.index == length then
                return
            end

            local mark_list = harpoon:list().items

            table.remove(mark_list, selection.index)
            table.insert(mark_list, selection.index + 1, selection.value)

            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:refresh(generate_new_finder(), { reset_prompt = true })
        end

        local move_mark_down = function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection.index == 1 then
                return
            end
            local mark_list = harpoon:list().items
            table.remove(mark_list, selection.index)
            table.insert(mark_list, selection.index - 1, selection.value)
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            current_picker:refresh(generate_new_finder(), { reset_prompt = true })
        end

        local function toggle_telescope()
            local opts = {}

            pickers.new(opts, {
                prompt_title = "Harpoon",
                finder = generate_new_finder(),
                sorter = conf.generic_sorter(opts),
                previewer = conf.grep_previewer(opts),
                attach_mappings = function(_, map)
                    map("i", "<c-d>", delete_harpoon_mark)
                    map("n", "<c-d>", delete_harpoon_mark)

                    map("i", "<c-p>", move_mark_up)
                    map("n", "<c-p>", move_mark_up)

                    map("i", "<c-n>", move_mark_down)
                    map("n", "<c-n>", move_mark_down)
                    return true
                end,
            }):find()
        end

        --vim.keymap.set("n", "<leader>e", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Add current file to Harpoon" })
        vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end,
            { desc = "Remove current file from Harpoon" })
        vim.keymap.set("n", "<leader>e", function() toggle_telescope() end,
            { desc = "Open Harpoon window in Telescope" })
        -- vim.keymap.set("n", "<leader>e", function() require('telescope').extensions.harpoon.marks() end,
        --     { desc = "Open Harpoon window in Telescope" })

        vim.keymap.set("n", "<leader>h", function() harpoon:list():select(1) end,
            { desc = "Select 1 buffer in Harpoon list" })
        vim.keymap.set("n", "<leader>j", function() harpoon:list():select(2) end,
            { desc = "Select 2 buffer in Harpoon list" })
        vim.keymap.set("n", "<leader>k", function() harpoon:list():select(3) end,
            { desc = "Select 3 buffer in Harpoon list" })
        vim.keymap.set("n", "<leader>l", function() harpoon:list():select(4) end,
            { desc = "Select 4 buffer in Harpoon list" })
    end
}
