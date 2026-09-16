---Renders what a view *would* look like, without applying it.
---
---The picker needs to answer "what am I about to switch to" before you commit,
---which the live tree cannot do -- it can only show the view you are already
---in. So this walks the filesystem itself, asking the same compiled view the
---real tree asks (`views.hides` / `views.opens`) rather than reimplementing the
---rules. If the preview and the tree ever disagree, it is a bug in one shared
---predicate, not a drift between two copies of the logic.
local views = require("tree-views")

local M = {}

-- Enough to show the shape of a region without turning the previewer into a
-- full recursive scan of a monorepo.
local MAX_ROWS = 400

--- Gitignore ----------------------------------------------------------------

-- `git ls-files --others --ignored --directory` collapses a whole ignored
-- directory into a single `node_modules/` entry, so one subprocess per repo
-- answers every question the walk will ask -- no per-path `check-ignore`.
-- Cached because Telescope re-previews on every cursor move.
local ignore_cache = {}

---Drop cached gitignore data. The picker calls this on open so a preview never
---reflects a repo state from an earlier session.
function M.invalidate()
    ignore_cache = {}
end

---@param root string
---@return table|nil { files = set, dirs = string[] }
local function ignored(root)
    if ignore_cache[root] ~= nil then
        return ignore_cache[root] or nil
    end

    local ok, res = pcall(function()
        return vim.system(
            { "git", "-C", root, "ls-files", "--others", "--ignored", "--exclude-standard", "--directory", "-z" },
            { text = true }
        ):wait(2000)
    end)

    if not ok or not res or res.code ~= 0 then
        -- Not a repo, or git is unhappy. Fall back to showing everything;
        -- a preview that is slightly too generous beats no preview.
        ignore_cache[root] = false
        return nil
    end

    local set = { files = {}, dirs = {} }
    for entry in vim.gsplit(res.stdout or "", "\0", { plain = true }) do
        if entry ~= "" then
            if entry:sub(-1) == "/" then
                table.insert(set.dirs, root .. "/" .. entry:sub(1, -2))
            else
                set.files[root .. "/" .. entry] = true
            end
        end
    end
    ignore_cache[root] = set
    return set
end

---@param set table|nil
---@param path string
---@return boolean
local function is_ignored(set, path)
    if not set then
        return false
    end
    if set.files[path] then
        return true
    end
    for _, dir in ipairs(set.dirs) do
        if path == dir or vim.startswith(path, dir .. "/") then
            return true
        end
    end
    return false
end

--- Walking ------------------------------------------------------------------

---@param dir string
---@return table[] { name, path, is_dir }
local function scan(dir)
    local entries = {}
    local fd = vim.uv.fs_scandir(dir)
    if not fd then
        return entries
    end
    while true do
        local name, kind = vim.uv.fs_scandir_next(fd)
        if not name then
            break
        end
        local path = dir .. "/" .. name
        if kind == "link" then
            local stat = vim.uv.fs_stat(path)
            kind = stat and stat.type or "file"
        end
        table.insert(entries, { name = name, path = path, is_dir = kind == "directory" })
    end
    -- Directories first, then case-insensitive by name: nvim-tree's own order.
    table.sort(entries, function(a, b)
        if a.is_dir ~= b.is_dir then
            return a.is_dir
        end
        return a.name:lower() < b.name:lower()
    end)
    return entries
end

--- Rendering ----------------------------------------------------------------

---@class PreviewOut
---@field lines string[]
---@field highlights table[] { line, col_start, col_end, group }
---@field paths string[] absolute path of every row drawn, in render order --
---       the machine-readable form of the preview, so a test can assert it
---       against what the live tree actually shows

---@param out PreviewOut
---@param text string
---@param hls table[]|nil { col_start, col_end, group }
local function push(out, text, hls)
    table.insert(out.lines, text)
    for _, h in ipairs(hls or {}) do
        table.insert(out.highlights, { #out.lines - 1, h[1], h[2], h[3] })
    end
end

---Wrap prose to a width, returning the wrapped lines.
---@param text string
---@param width integer
---@return string[]
local function wrap(text, width)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        if line == "" then
            line = word
        elseif #line + #word + 1 <= width then
            line = line .. " " .. word
        else
            table.insert(lines, line)
            line = word
        end
    end
    if line ~= "" then
        table.insert(lines, line)
    end
    return lines
end

---Join a list for a summary row, eliding the tail when it runs long.
---@param items string[]|nil
---@param width integer
---@return string|nil
local function summarize(items, width)
    if not items or #items == 0 then
        return nil
    end
    local text = table.concat(items, ", ")
    if #text <= width then
        return text
    end
    local kept = {}
    local used = 0
    for _, item in ipairs(items) do
        if used + #item + 2 > width - 8 then
            break
        end
        table.insert(kept, item)
        used = used + #item + 2
    end
    return ("%s  +%d more"):format(table.concat(kept, ", "), #items - #kept)
end

---@param out PreviewOut
---@param key string
---@param value string|nil
local function row(out, key, value)
    if not value then
        return
    end
    local label = ("  %-9s"):format(key)
    push(out, label .. value, { { 2, 2 + #key, "Identifier" } })
end

---Header block: what this view is, and the rules it applies.
---@param out PreviewOut
---@param c CompiledView
---@param width integer
local function header(out, c, width)
    local spec = c.spec

    local group = views.group_of(c.name) .. " / "
    local active = views.active == c.name and "  (active)" or ""
    local at = 2 + #group
    push(out, "  " .. group .. c.name .. active, {
        { 2, at, "Comment" },
        { at, at + #c.name, "Title" },
        { at + #c.name, at + #c.name + #active, "DiagnosticOk" },
    })
    if spec.desc then
        push(out, "  " .. spec.desc, { { 0, -1, "Comment" } })
    end
    push(out, "")

    if spec.about then
        for _, line in ipairs(wrap(spec.about, width - 4)) do
            push(out, "  " .. line)
        end
        push(out, "")
    end

    row(out, "root", vim.fn.fnamemodify(c.root, ":~"))
    row(out, "showing", summarize(spec.only, width - 12) or "everything under root")
    row(out, "hiding", summarize(spec.hide, width - 12))
    row(out, "opening", summarize(spec.expand, width - 12))

    local extra = {}
    if spec.git_ignored then
        table.insert(extra, "gitignored hidden")
    end
    if spec.dotfiles then
        table.insert(extra, "dotfiles hidden")
    end
    row(out, "filters", #extra > 0 and table.concat(extra, " · ") or nil)

    push(out, "")
    push(out, "  " .. string.rep("─", math.max(0, width - 4)), { { 0, -1, "Comment" } })
    push(out, "")
end

---Recursively render the visible tree under `dir`.
---@param out PreviewOut
---@param c CompiledView
---@param dir string
---@param prefix string
---@param set table|nil gitignore set
---@param counts table { files, dirs, truncated }
local function walk(out, c, dir, prefix, set, counts)
    if counts.truncated then
        return
    end

    local visible = {}
    for _, entry in ipairs(scan(dir)) do
        local skip = views.hides(c, entry.path)
            or (c.spec.dotfiles and entry.name:sub(1, 1) == ".")
            or (c.spec.git_ignored and is_ignored(set, entry.path))
        if not skip then
            table.insert(visible, entry)
        end
    end

    for i, entry in ipairs(visible) do
        if #out.lines >= MAX_ROWS then
            counts.truncated = true
            return
        end

        local last = i == #visible
        local branch = last and "└─ " or "├─ "
        local open = entry.is_dir and views.opens(c, entry.path)
        local marker = entry.is_dir and (open and "▾ " or "▸ ") or "  "
        local name = entry.name .. (entry.is_dir and "/" or "")

        table.insert(out.paths, entry.path)

        local guides = prefix .. branch
        local name_at = #guides + #marker
        push(out, guides .. marker .. name, {
            { 0, #guides, "Comment" },
            { #guides, name_at, entry.is_dir and "Directory" or "Comment" },
            { name_at, name_at + #name, entry.is_dir and "Directory" or "Normal" },
        })

        if entry.is_dir then
            counts.dirs = counts.dirs + 1
        else
            counts.files = counts.files + 1
        end

        if open then
            walk(out, c, entry.path, prefix .. (last and "   " or "│  "), set, counts)
        end
    end
end

---Render a view's preview.
---@param name string
---@param width integer preview window width
---@return PreviewOut
function M.render(name, width)
    width = math.max(width or 60, 30)
    local out = { lines = {}, highlights = {}, paths = {} }

    local c, err = views.compile(name)
    if not c then
        push(out, "")
        push(out, "  " .. err, { { 0, -1, "ErrorMsg" } })
        return out
    end

    push(out, "")
    header(out, c, width)

    local root_name = vim.fn.fnamemodify(c.root, ":t")
    push(out, "▾ " .. root_name .. "/", { { 0, -1, "NvimTreeRootFolder" } })

    local counts = { files = 0, dirs = 0, truncated = false }
    local set = c.spec.git_ignored and ignored(c.root) or nil
    walk(out, c, c.root, "", set, counts)

    push(out, "")
    if counts.truncated then
        push(out, ("  … truncated at %d rows"):format(MAX_ROWS), { { 0, -1, "WarningMsg" } })
    end
    push(out, ("  %d directories, %d files shown"):format(counts.dirs, counts.files),
        { { 0, -1, "Comment" } })

    return out
end

return M
