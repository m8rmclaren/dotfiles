local harpoon = require("harpoon")
local conf = require("telescope.config").values

harpoon:setup()

-- basic telescope configuration
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

--vim.keymap.set("n", "<leader>e", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end, { desc = "Add current file to Harpoon" })
vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end, { desc = "Remove current file from Harpoon" })
vim.keymap.set("n", "<leader>e", function() toggle_telescope(harpoon:list()) end, { desc = "Open Harpoon window in Telescope" })

vim.keymap.set("n", "<leader>h", function() harpoon:list():select(1) end, { desc = "Select 1 buffer in Harpoon list" })
vim.keymap.set("n", "<leader>j", function() harpoon:list():select(2) end, { desc = "Select 2 buffer in Harpoon list" })
vim.keymap.set("n", "<leader>k", function() harpoon:list():select(3) end, { desc = "Select 3 buffer in Harpoon list" })
vim.keymap.set("n", "<leader>l", function() harpoon:list():select(4) end, { desc = "Select 4 buffer in Harpoon list" })
