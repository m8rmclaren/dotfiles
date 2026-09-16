---Telescope picker for tree-views, with a preview of the tree each view builds.
---
---Falls back to `vim.ui.select` when Telescope is not loaded, so the keymap
---works in a stripped-down session too.
local views = require("tree-views")

local M = {}

local CLEAR = "<clear>"

---@return string[]
local function entries()
    local names = views.ordered()
    if views.active then
        table.insert(names, 1, CLEAR)
    end
    return names
end

---@param name string
local function choose(name)
    if name == CLEAR then
        views.clear()
    else
        views.apply(name)
    end
end

--- Fallback -----------------------------------------------------------------

local function select_fallback()
    local names = entries()
    local width = 0
    for _, name in ipairs(names) do
        width = math.max(width, #name)
    end
    vim.ui.select(names, {
        prompt = "nvim-tree view",
        format_item = function(name)
            if name == CLEAR then
                return "  <clear>  show everything"
            end
            local spec = views.views[name]
            local marker = name == views.active and "* " or "  "
            return ("%s%-" .. width .. "s  %s  %s"):format(
                marker, name, views.group_of(name), spec.desc or "")
        end,
    }, function(choice)
        if choice then
            choose(choice)
        end
    end)
end

--- Telescope ----------------------------------------------------------------

---Column widths sized to the actual data, so a long name like
---`chrome-extension` can't run into the description column.
---@param names string[]
---@return table displayer, integer group_width, integer name_width
local function layout(names)
    local entry_display = require("telescope.pickers.entry_display")
    local group_w, name_w = 0, 0
    for _, name in ipairs(names) do
        if name ~= CLEAR then
            group_w = math.max(group_w, #views.group_of(name))
            name_w = math.max(name_w, #name)
        end
    end
    local displayer = entry_display.create({
        separator = "  ",
        items = {
            { width = 1 },        -- active marker
            { width = group_w },
            { width = name_w },
            { remaining = true },
        },
    })
    return displayer, group_w, name_w
end

---The group of the row directly above this one *in the currently filtered
---list*. Telescope calls the display function as `entry:display(picker)`, so
---the live entry manager is reachable from here -- which means the group label
---can be blanked on repeats and still be correct after you start typing, rather
---than being frozen to the unfiltered neighbour at entry-construction time.
---@param picker table|nil
---@param entry table
---@return string|nil
local function group_above(picker, entry)
    local manager = picker and picker.manager
    if not manager then
        return nil
    end
    local ok, index = pcall(manager.find_entry, manager, entry)
    if not ok or type(index) ~= "number" or index <= 1 then
        return nil
    end
    local ok2, prev = pcall(manager.get_entry, manager, index - 1)
    if not ok2 or not prev or prev.value == CLEAR then
        return nil
    end
    return views.group_of(prev.value)
end

---Rows are grouped by a repeated group column rather than by heading rows.
---Headings would be entries Telescope could select, and would vanish the moment
---you typed anything; a column stays correct under filtering and is searchable
---— typing "chartport" narrows to that group. The label is drawn only on the
---first row of each run, so each group reads as a block.
---@param displayer table
---@return function
local function make_display(displayer)
    return function(entry, picker)
        local name = entry.value
        if name == CLEAR then
            return displayer({
                { "⨯", "DiagnosticWarn" },
                "",
                { "clear", "DiagnosticWarn" },
                { "show everything", "Comment" },
            })
        end
        local spec = views.views[name] or {}
        local group = views.group_of(name)
        return displayer({
            views.active == name and { "●", "DiagnosticOk" } or " ",
            group == group_above(picker, entry) and "" or { group, "Comment" },
            { name, "Title" },
            { spec.desc or "", "Comment" },
        })
    end
end

local function telescope_pick()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local preview = require("tree-views.preview")

    -- Repo state may have moved since the last time the picker ran.
    preview.invalidate()

    local ns = vim.api.nvim_create_namespace("TreeViewsPreview")
    local names = entries()
    local display = make_display(layout(names))

    local previewer = previewers.new_buffer_previewer({
        title = "View",
        -- Key previews by view name so Telescope reuses one buffer per view
        -- instead of re-walking the filesystem on every cursor bounce.
        get_buffer_by_name = function(_, entry)
            return entry.value
        end,
        define_preview = function(self, entry, status)
            local bufnr = self.state.bufnr
            if entry.value == CLEAR then
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false,
                    { "", "  Clear the active view and show the whole tree again." })
                vim.api.nvim_buf_add_highlight(bufnr, ns, "Comment", 1, 0, -1)
                return
            end

            local width = vim.api.nvim_win_get_width(status.preview_win or self.state.winid or 0)
            local ok, out = pcall(preview.render, entry.value, width - 2)
            if not ok then
                out = { lines = { "", "  preview failed: " .. tostring(out) }, highlights = {} }
            end

            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out.lines)
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
            for _, h in ipairs(out.highlights) do
                pcall(vim.api.nvim_buf_add_highlight, bufnr, ns, h[4], h[1], h[2], h[3])
            end
        end,
    })

    pickers.new({
        -- Telescope defaults to filling the list from the bottom up, which
        -- would render the group order upside down. Read downwards instead,
        -- with the prompt above the results.
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
    }, {
        prompt_title = "nvim-tree views",
        finder = finders.new_table({
            results = names,
            entry_maker = function(name)
                return {
                    value = name,
                    -- Match on group, name and description together, so both
                    -- "chartport" and "backend" find the right view.
                    ordinal = table.concat({
                        views.group_of(name),
                        name,
                        (views.views[name] or {}).desc or "",
                    }, " "),
                    display = display,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewer,
        attach_mappings = function(bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(bufnr)
                if selection then
                    choose(selection.value)
                end
            end)
            return true
        end,
    }):find()
end

---Open the picker.
function M.pick()
    if pcall(require, "telescope") then
        local ok, err = pcall(telescope_pick)
        if ok then
            return
        end
        vim.notify("tree-views: telescope picker failed (" .. tostring(err) .. ")", vim.log.levels.WARN)
    end
    select_fallback()
end

return M
