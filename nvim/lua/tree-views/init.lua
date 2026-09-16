---Named "views" into a codebase, for nvim-tree.
---
---A view is a saved answer to "which part of this repo am I in right now": an
---optional root to jump to, a subset of paths to show, globs to hide, and
---directories to open so the shape of the area is visible the moment you land
---in it. Switching views is one keystroke, so a monorepo stops looking like an
---undifferentiated wall of directories.
---
---Views come from two places, merged per project:
---  * `lua/tree-views/views.lua` -- global, reachable from inside every project.
---  * `<main checkout>/.nvim/tree-views.lua` -- the project's own, read from the
---    repo's main worktree so every worktree sees one definition. Roots there are
---    relative to *your* checkout, so a view follows you into a worktree.
---This file is just the machinery.
---
---How it hooks into nvim-tree:
---  * `M.filter` is handed to `filters.custom`, which nvim-tree accepts as a
---    `fun(absolute_path): boolean` (true = hide). It reads the active view at
---    call time, so views can be swapped without re-running setup.
---  * `M.root_label` is handed to `renderer.root_folder_label`, so the header
---    line names the view you're in.
---  * Expansion rides on `api.tree.expand_all`'s `expand_until` predicate,
---    which controls both which directories open and which get descended into.
local M = {}

---@class TreeView
---@field group?       string   heading this view sorts under in the picker
---@field desc?        string   one-line summary, shown on the picker row
---@field about?       string   longer prose shown in the picker preview: what this
---                             region of the codebase actually is, and when to be in it
---@field root?        string   tree root for this view. Absolute or `~`-rooted is taken as
---                             written; anything else is relative to the current checkout.
---                             Defaults to the checkout for a project view, and to the
---                             tree's current root for a global one.
---@field only?        string[] path prefixes (relative to root) to show; everything else is hidden
---@field hide?        string[] globs (relative to root, or a bare basename) to hide, along with their subtrees
---@field expand?      string[] directories (relative to root) to open; a `/**` suffix opens the whole subtree
---@field dotfiles?    boolean  hide dotfiles while this view is active
---@field git_ignored? boolean  hide gitignored files while this view is active

---@type table<string, TreeView>
M.views = {}

---Group display order. Groups named here come first, in this order; anything
---else falls in alphabetically behind them.
---@type string[]
M.groups = {}

---Views defined by this Neovim config, reachable from inside every project.
---`M.views` is these merged with whatever the current project defines.
---@type table<string, TreeView>
M.global = {}

---Where each view in `M.views` came from: "global" or "project".
---@type table<string, string>
M.sources = {}

---Name of the active view, or nil.
---@type string|nil
M.active = nil

---Strip trailing slashes without eating a lone "/".
---@param path string
---@return string
local function trim_slash(path)
    return (path:gsub("(.)/+$", "%1"))
end

---Resolve a possibly-relative, possibly-`~` path against a root.
---@param path string
---@param root string|nil
---@return string
local function resolve(path, root)
    path = vim.fs.normalize(path)
    if root and path:sub(1, 1) ~= "/" then
        path = root .. "/" .. path
    end
    return trim_slash(path)
end

---The live explorer, or nil before nvim-tree has opened once.
---@return table|nil
local function explorer()
    local ok, core = pcall(require, "nvim-tree.core")
    return ok and core.get_explorer() or nil
end

---The root a view without an explicit `root` applies to: whatever the tree is
---currently showing.
---@return string
local function current_tree_root()
    local e = explorer()
    return trim_slash(vim.fs.normalize(e and e.absolute_path or vim.fn.getcwd()))
end

--- The project --------------------------------------------------------------

---Where a project keeps its own views, relative to the main checkout.
local VIEW_FILE = ".nvim/tree-views.lua"

---The checkout views are resolved against, and the repo behind it.
---@class Project
---@field root string current checkout: what relative view roots resolve against
---@field main string main worktree: the one identity every worktree of the repo shares
---@field file string the project's view file, whether or not it exists

---@type Project|nil
M.project = nil

---The directory the project was detected from, kept for error messages.
---@type string|nil
local detected_from = nil

---Group order contributed by `setup`, as opposed to by the project.
---@type string[]
local global_groups = {}

---Whether the project's views have been merged in yet.
local loaded = false

---Find the checkout containing `dir`, and the repo behind it.
---
---git answers two different questions here and both matter. `--show-toplevel` is
---*this* checkout, which is what relative view roots resolve against: open nvim
---in a worktree and its views point into that worktree, instead of dragging you
---back to the main one. `--git-common-dir` is shared by every worktree of the
---repo, so its parent names the project itself -- the same answer from whichever
---branch you happen to be sitting on.
---@param dir string
---@return Project|nil
local function detect(dir)
    local out = vim.system({
        "git", "-C", dir, "rev-parse", "--path-format=absolute", "--show-toplevel", "--git-common-dir",
    }, { text = true }):wait()
    if out.code ~= 0 then
        return nil
    end

    local lines = vim.split(vim.trim(out.stdout or ""), "\n", { trimempty = true })
    if #lines < 2 then
        return nil
    end

    local main = trim_slash(vim.fs.normalize(vim.fs.dirname(lines[2])))
    return {
        root = trim_slash(vim.fs.normalize(lines[1])),
        main = main,
        file = main .. "/" .. VIEW_FILE,
    }
end

---Read the project's view file.
---
---From the *main* checkout, never the current one. The file is tracked, and a
---worktree cut from a branch months ago carries that branch's copy of every
---tracked file -- so read locally, views would quietly rot back to whatever the
---repo looked like when the branch started, or name directories that branch does
---not have. One checkout owns the definitions; every worktree reads them.
---
---`vim.secure.read` is the gate: nvim's own trust database, the same one `exrc`
---uses. The file runs only once you have said yes to its exact contents, and
---editing it asks again.
---@return table<string, TreeView> views
---@return string[] groups
local function read_project_views()
    local p = M.project
    if not p or vim.fn.filereadable(p.file) == 0 then
        return {}, {}
    end

    local ok, contents = pcall(vim.secure.read, p.file)
    if not ok or type(contents) ~= "string" then
        -- Not an error -- the global views are still there -- but it must not be
        -- silent. `vim.secure.read` returns nil for "ignore", "view" and "deny"
        -- alike, and its prompt defaults to *ignore*, so a stray <CR> at a
        -- crowded message screen is enough to land here. Quietly returning
        -- nothing is how you end up staring at a picker holding only the editor
        -- views, with no idea the project ever had any.
        vim.notify(table.concat({
            ("tree-views: %s is not trusted, so this project's views were not loaded.")
                :format(vim.fn.fnamemodify(p.file, ":~")),
            "  :TreeViewProject  asks again -- answer (a)llow.",
            ('  Answered (d)eny? That one sticks: :lua vim.secure.trust{ action = "remove", path = %q }')
                :format(p.file),
        }, "\n"), vim.log.levels.WARN)
        return {}, {}
    end

    local chunk, syntax_err = load(contents, "@" .. p.file)
    if not chunk then
        vim.notify(("tree-views: %s: %s"):format(p.file, syntax_err), vim.log.levels.ERROR)
        return {}, {}
    end

    local ran, result = pcall(chunk)
    if not ran then
        vim.notify(("tree-views: %s: %s"):format(p.file, result), vim.log.levels.ERROR)
        return {}, {}
    end
    if type(result) ~= "table" then
        vim.notify(("tree-views: %s did not return a table"):format(p.file), vim.log.levels.ERROR)
        return {}, {}
    end

    -- Either a bare table of views, or `{ views = ..., groups = ... }` for a
    -- project that wants to order its own picker headings.
    if type(result.views) == "table" then
        return result.views, type(result.groups) == "table" and result.groups or {}
    end
    return result, {}
end

---Merge the global views with the current project's.
---
---Deferred to the first time anything actually asks for a view, rather than run
---from `setup`: reading the project file can raise a trust prompt, which has no
---business firing during startup. Runs at most once per project.
local function ensure_loaded()
    if loaded then
        return
    end
    loaded = true

    local project_views, project_groups = read_project_views()

    M.views, M.sources = {}, {}
    for name, spec in pairs(project_views) do
        M.views[name] = spec
        M.sources[name] = "project"
    end
    for name, spec in pairs(M.global) do
        if M.sources[name] then
            -- Global wins. Being reachable from inside every project is the whole
            -- point of a global view, so a project must not be able to take one
            -- of their names away.
            vim.notify(
                ("tree-views: %s: %q is shadowed by a global view of the same name")
                :format(M.project and M.project.file or "project", name),
                vim.log.levels.WARN
            )
        end
        M.views[name] = spec
        M.sources[name] = "global"
    end

    -- Picker order: the project's groups first, then the global ones. This config
    -- should not have to know the group names some work repo invented, so a
    -- project orders its own and anything it leaves out sorts alphabetically
    -- behind the ones it named.
    local seen, order = {}, {}
    local function add(group)
        if group and group ~= "" and not seen[group] then
            seen[group] = true
            table.insert(order, group)
        end
    end
    for _, group in ipairs(project_groups) do
        add(group)
    end
    local rest = {}
    for name, source in pairs(M.sources) do
        if source == "project" and not seen[M.group_of(name)] then
            table.insert(rest, M.group_of(name))
        end
    end
    table.sort(rest)
    for _, group in ipairs(rest) do
        add(group)
    end
    for _, group in ipairs(global_groups) do
        add(group)
    end
    M.groups = order
end

--- Compiling ----------------------------------------------------------------

---A view compiled into the form both the live filter and the preview consume:
---absolute root, normalized `only` prefixes, `hide` globs as lpeg patterns, and
---`expand` entries split into path + depth. Everything path- and glob-shaped is
---resolved exactly once here, so nothing downstream has to re-parse a spec --
---and, more importantly, the preview and the real tree cannot drift apart,
---because they are reading the same compiled object.
---@class CompiledView
---@field name    string
---@field spec    TreeView
---@field root    string
---@field only    string[]|nil
---@field hide    table[]   lpeg patterns
---@field targets table[]   { path = string, deep = boolean }

---Where a view's tree is rooted.
---
---An absolute or `~`-rooted `root` is taken as written -- that is how the editor
---views reach ~/.config from inside a work repo. Anything else resolves against
---the current checkout, so one definition follows you into whichever worktree you
---opened nvim in rather than pinning you to the path it was written against.
---@param name string
---@param spec TreeView
---@return string|nil root
---@return string|nil error
local function view_root(name, spec)
    if not spec.root then
        -- Said nothing. A project view is about a region of its project, so it
        -- means the checkout; a global view has no project to lean on and stays
        -- wherever the tree already is.
        if M.sources[name] == "project" and M.project then
            return M.project.root
        end
        return current_tree_root()
    end

    local path = vim.fs.normalize(spec.root)
    if path:sub(1, 1) ~= "/" then
        if not M.project then
            return nil, ("%s: root %q is relative, but %s is not inside a git checkout")
                :format(name, spec.root, vim.fn.fnamemodify(detected_from or vim.fn.getcwd(), ":~"))
        end
        -- Normalized again on the way out: that is what collapses the "." of a
        -- `root = "."` into the checkout itself.
        path = vim.fs.normalize(M.project.root .. "/" .. path)
    end

    path = trim_slash(path)
    if vim.fn.isdirectory(path) == 0 then
        return nil, ("%s: root %s does not exist"):format(name, path)
    end
    return path
end

---@param name string
---@return CompiledView|nil
---@return string|nil error
function M.compile(name)
    ensure_loaded()

    local spec = M.views[name]
    if not spec then
        return nil, ("no view named %q"):format(name)
    end

    local root, root_err = view_root(name, spec)
    if not root then
        return nil, root_err
    end

    local hide = {}
    for _, glob in ipairs(spec.hide or {}) do
        local ok, pattern = pcall(vim.glob.to_lpeg, glob)
        if ok then
            table.insert(hide, pattern)
        else
            vim.notify(("tree-views: %s: bad glob %q"):format(name, glob), vim.log.levels.WARN)
        end
    end

    local only = nil
    if spec.only and #spec.only > 0 then
        only = {}
        for _, prefix in ipairs(spec.only) do
            table.insert(only, trim_slash(vim.fs.normalize(prefix)))
        end
    end

    local targets = {}
    for _, entry in ipairs(spec.expand or {}) do
        local deep = entry:sub(-3) == "/**"
        table.insert(targets, {
            path = resolve(deep and entry:sub(1, -4) or entry, root),
            deep = deep,
        })
    end

    return { name = name, spec = spec, root = root, only = only, hide = hide, targets = targets }
end

--- Filtering -----------------------------------------------------------------

---Would this view hide `path`? Pure: no dependency on the live tree, so the
---previewer can ask about a view that is not (and may never be) active.
---@param c CompiledView
---@param path string absolute path
---@return boolean hide
function M.hides(c, path)
    path = trim_slash(vim.fs.normalize(path))
    if path == c.root then
        return false
    end
    if not vim.startswith(path, c.root .. "/") then
        -- Outside the view's root -- the tree was rerooted somewhere the view
        -- has no opinion about. Say nothing rather than hiding everything.
        return false
    end
    local rel = path:sub(#c.root + 2)

    if c.only then
        local keep = false
        for _, prefix in ipairs(c.only) do
            -- Keep a path that is the prefix, sits under it, or is an ancestor
            -- of it: `cmd` has to survive in order to reveal `cmd/server`.
            if rel == prefix
                or vim.startswith(rel, prefix .. "/")
                or vim.startswith(prefix, rel .. "/")
            then
                keep = true
                break
            end
        end
        if not keep then
            return true
        end
    end

    -- Match globs against the path relative to root *and* against the bare
    -- basename, mirroring how nvim-tree treats its own `filters.custom`
    -- strings -- so `node_modules` works without spelling it `**/node_modules`.
    local base = rel:match("[^/]+$") or rel
    for _, glob in ipairs(c.hide) do
        if glob:match(rel) == #rel + 1 or glob:match(base) == #base + 1 then
            return true
        end
    end

    return false
end

---Should this view open `path` (a directory)? Also pure, and the shared source
---of truth behind both the real `expand_until` predicate and the preview.
---@param c CompiledView
---@param path string absolute path
---@return boolean
function M.opens(c, path)
    path = trim_slash(vim.fs.normalize(path))
    for _, t in ipairs(c.targets) do
        if path == t.path then
            return true
        elseif vim.startswith(t.path, path .. "/") then
            -- An ancestor of a target: open it to get further down.
            return true
        elseif t.deep and vim.startswith(path, t.path .. "/") then
            return true
        end
    end
    return false
end

-- Precompiled form of the active view. nvim-tree calls the filter once per path
-- per scan, so activation pays for the glob compilation and path resolution and
-- the hot path is left with plain string comparisons.
---@type CompiledView|nil
local active = nil

---Hand this to nvim-tree's `filters.custom`.
---@param path string absolute path
---@return boolean hide
function M.filter(path)
    return active ~= nil and M.hides(active, path)
end

--- Header label --------------------------------------------------------------

---Hand this to nvim-tree's `renderer.root_folder_label`.
---@param path string absolute path of the tree root
---@return string
function M.root_label(path)
    path = trim_slash(vim.fs.normalize(path))
    local label = vim.fn.fnamemodify(path, ":t")

    -- Inside a project the basename alone is ambiguous: every worktree has a
    -- `web`, so `web  [web]` does not say which checkout you are looking at.
    -- Naming the checkout tells `reader-mode/web` from `hermes/web`.
    local p = M.project
    if p and path == p.root then
        label = vim.fn.fnamemodify(p.root, ":t")
    elseif p and vim.startswith(path, p.root .. "/") then
        label = vim.fn.fnamemodify(p.root, ":t") .. "/" .. path:sub(#p.root + 2)
    end

    if M.active then
        return string.format("%s  [%s]", label, M.active)
    end
    return label
end

--- Applying ------------------------------------------------------------------

---Build the `expand_until` predicate for a compiled view.
---@param c CompiledView
---@return fun(count: integer, node: table): boolean
local function expander(c)
    return function(_, node)
        -- The expansion iterator walks filtered-out nodes too, so an
        -- `expand` entry must never drag a hidden `node_modules` back in.
        if node.hidden or not node.absolute_path then
            return false
        end
        return M.opens(c, node.absolute_path)
    end
end

local BORROWED = { "dotfiles", "git_ignored" }

-- What the tree looked like before views took over: its root, and nvim-tree's
-- own dotfile/gitignore filters, which views only borrow. Captured when the
-- first view is applied and handed back by `clear()`, so clearing returns you
-- to the tree you started the session with rather than stranding you in
-- whichever view happened to be last.
--
-- The root matters more than it looks: `api.tree.change_root` runs `lcd` and
-- rebuilds the explorer, so a view that re-roots also moves Vim's working
-- directory. Restoring the root is what puts the cwd back too.
---@type { root: string, filters: table<string, boolean> }|nil
local origin = nil

---Snapshot the pre-view tree, once, before anything mutates it.
local function capture_origin()
    if origin then
        return
    end
    local filters = {}
    local e = explorer()
    if e and e.filters then
        for _, kind in ipairs(BORROWED) do
            filters[kind] = e.filters.state[kind]
        end
    end
    origin = { root = current_tree_root(), filters = filters }
end

---Set one of nvim-tree's built-in filters to an explicit value. Its API only
---exposes toggles, so read the current state and flip only on a mismatch.
---@param kind string
---@param want boolean|nil
local function set_builtin_filter(kind, want)
    if want == nil then
        return
    end
    local e = explorer()
    if not e or not e.filters then
        return
    end
    if e.filters.state[kind] ~= want then
        e.filters:toggle(kind)
    end
end

---Apply a view's borrowed-filter overrides.
---
---Must run *after* any root change: rebuilding the explorer constructs a fresh
---Filters from the setup options, discarding whatever was toggled before.
---@param spec TreeView
local function borrow_filters(spec)
    for _, kind in ipairs(BORROWED) do
        -- Fall back to the pre-view setting, so a view that says nothing about
        -- `dotfiles` inherits the original rather than the previous view's.
        -- Assigned in two steps, not `a or b`: the fallback is usually `false`,
        -- which `or` would collapse into "no opinion" and leave the previous
        -- view's setting in place.
        local want = spec[kind]
        if want == nil and origin then
            want = origin.filters[kind]
        end
        set_builtin_filter(kind, want)
    end
end

---Activate a view by name.
---@param name string
function M.apply(name)
    local c, err = M.compile(name)
    if not c then
        vim.notify("tree-views: " .. err, vim.log.levels.ERROR)
        return
    end

    local api = require("nvim-tree.api")

    -- Before the first view moves anything, remember where we were.
    capture_origin()

    active = c
    M.active = name

    -- Root first: changing it rebuilds the explorer, and we want that rebuild
    -- to already see this view's filter.
    if c.root ~= current_tree_root() then
        api.tree.change_root(c.root)
    end

    borrow_filters(c.spec)

    api.tree.reload()
    api.tree.collapse_all()

    if #c.targets > 0 then
        -- Expansion has to run against a populated tree, and `expand_all` needs
        -- an explicit node because its public wrapper otherwise reaches for
        -- whatever is under the cursor -- which is not the root, and may not
        -- even be in the tree window.
        vim.schedule(function()
            local e = explorer()
            if e then
                pcall(api.tree.expand_all, e, { expand_until = expander(c) })
            end
        end)
    end
end

---Drop back to the tree as it was before any view was applied: original root
---(which also restores the working directory), original dotfile/gitignore
---filters, no path filtering, and collapsed.
function M.clear()
    if not M.active then
        return
    end
    local api = require("nvim-tree.api")

    M.active = nil
    active = nil

    local o = origin
    origin = nil

    if o then
        -- Root first. Changing it rebuilds the explorer with filters reset to
        -- the setup defaults, so restoring them afterwards is the only order
        -- that sticks.
        if o.root ~= current_tree_root() then
            api.tree.change_root(o.root)
        end
        for _, kind in ipairs(BORROWED) do
            set_builtin_filter(kind, o.filters[kind])
        end
    end

    api.tree.reload()
    api.tree.collapse_all()
end

---Alphabetical list of view names, for command completion.
---@return string[]
function M.names()
    ensure_loaded()
    local names = vim.tbl_keys(M.views)
    table.sort(names)
    return names
end

local UNGROUPED = "other"

---The group a view belongs to.
---@param name string
---@return string
function M.group_of(name)
    local spec = M.views[name]
    return spec and spec.group or UNGROUPED
end

---View names in picker order: by group (respecting `M.groups`), then by name
---within each group. This is the order the picker renders top-to-bottom, so
---related views sit together instead of being scattered by the alphabet.
---@return string[]
function M.ordered()
    ensure_loaded()

    local rank = {}
    for i, group in ipairs(M.groups) do
        rank[group] = i
    end

    local names = M.names()
    table.sort(names, function(a, b)
        local ga, gb = M.group_of(a), M.group_of(b)
        if ga ~= gb then
            local ra, rb = rank[ga], rank[gb]
            if ra and rb then
                return ra < rb
            elseif ra or rb then
                -- An explicitly ordered group always precedes an unlisted one.
                return ra ~= nil
            end
            return ga < gb
        end
        return a < b
    end)
    return names
end

---Pick a view interactively -- Telescope when it is available, `vim.ui.select`
---otherwise.
function M.pick()
    ensure_loaded()
    if vim.tbl_isempty(M.views) then
        vim.notify("tree-views: no views configured", vim.log.levels.WARN)
        return
    end
    require("tree-views.picker").pick()
end

--- Setup ---------------------------------------------------------------------

---Point tree-views at the project containing `dir`, dropping whatever was
---loaded for the last one.
---@param dir string
local function use_project(dir)
    detected_from = trim_slash(vim.fs.normalize(vim.fn.fnamemodify(dir, ":p")))
    M.project = detect(detected_from)
    loaded = false
    M.views, M.sources, M.groups = {}, {}, {}
end

---@param opts { global: table<string, TreeView>, groups?: string[] }
function M.setup(opts)
    opts = opts or {}
    M.global = opts.global or {}
    global_groups = opts.groups or {}

    -- Detect now, from the directory nvim started in, and not a moment later.
    -- `api.tree.change_root` runs `lcd` (nvim-tree/actions/root/change-dir.lua),
    -- so applying any view moves the working directory -- and applying an editor
    -- view moves it clean out of the project. Resolved on demand, the project
    -- would therefore change identity as a side effect of switching views,
    -- swapping the entire view set out from under you. This cwd is the last one
    -- that is still the truth.
    use_project(vim.fn.getcwd())

    vim.api.nvim_create_user_command("TreeView", function(cmd)
        if cmd.args == "" then
            M.pick()
        else
            M.apply(cmd.args)
        end
    end, {
        nargs = "?",
        desc = "Switch nvim-tree to a named view",
        complete = function(lead)
            return vim.tbl_filter(function(n) return vim.startswith(n, lead) end, M.names())
        end,
    })

    vim.api.nvim_create_user_command("TreeViewClear", function()
        M.clear()
    end, { desc = "Clear the active nvim-tree view" })

    vim.api.nvim_create_user_command("TreeViewProject", function(cmd)
        if cmd.args ~= "" then
            use_project(vim.fn.expand(cmd.args))
        else
            -- No argument: same project, but re-read its file. This is the
            -- command you run after editing the views themselves.
            loaded = false
        end
        ensure_loaded()

        local p = M.project
        if not p then
            vim.notify(("tree-views: %s is not inside a git checkout -- global views only")
                :format(vim.fn.fnamemodify(detected_from, ":~")))
            return
        end

        local n = 0
        for _, source in pairs(M.sources) do
            if source == "project" then
                n = n + 1
            end
        end
        vim.notify(("tree-views: %s\n  checkout  %s\n  views     %s (%d)"):format(
            vim.fn.fnamemodify(p.main, ":t"),
            vim.fn.fnamemodify(p.root, ":~"),
            vim.fn.fnamemodify(p.file, ":~") .. (vim.fn.filereadable(p.file) == 1 and "" or "  -- missing"),
            n))
    end, {
        nargs = "?",
        complete = "dir",
        desc = "Show the project tree-views resolves against, reload it, or point it elsewhere",
    })
end

return M
