---Global views: the ones that follow you into every project.
---
---A project's own views do not live here. They live in that repo, at
---`.nvim/tree-views.lua` in its main checkout, and are merged with these
---whenever nvim starts inside it -- see `lua/tree-views/init.lua`. Anything
---you want reachable *while* working in some other repo belongs here instead,
---which is why the editor views do.
---
---Every field is optional:
---
---  group        heading the view sorts under in the picker. Global groups sort
---               after the current project's; order them via `groups` in
---               lua/plugins/nvim-tree.lua.
---  desc         one-line summary, shown on the picker row
---  about        a paragraph shown in the picker preview: what this region of
---               the codebase actually is, and when you'd want to be in it
---  root         where to point the tree. A global view wants an absolute or
---               `~`-rooted path -- a relative one would resolve against
---               whichever checkout you happen to have opened.
---  only         path prefixes (relative to root) to show -- everything else
---               goes away. Ancestors of a prefix stay visible, so listing
---               `internal/handler` still leaves `internal` there to walk through.
---  hide         globs, matched against both the path relative to root and the
---               bare basename, so `node_modules` works as well as
---               `**/node_modules`. Hiding a directory hides its whole subtree,
---               and nvim-tree never scans into it.
---  expand       directories to open on entry. A `/**` suffix opens everything
---               beneath, otherwise just that one directory is opened.
---  dotfiles     true hides dotfiles while the view is active
---  git_ignored  true hides gitignored files while the view is active
---
---`only` and `hide` compose: `only` narrows to a region, `hide` prunes noise
---inside it.

return {
    config = {
        group = "editor",
        desc = "Neovim config",
        about = "This Neovim config. lua/plugins holds one file per lazy.nvim spec, "
            .. "lua/lsp the language server wiring, and lua/set.lua + lua/remap.lua the "
            .. "editor basics.",
        root = "~/.config/nvim",
        only = { "init.lua", "lua", "lazy-lock.json" },
        expand = { "lua/**" },
        dotfiles = true,
    },

    dotfiles = {
        group = "editor",
        desc = "Everything under ~/.config",
        about = "Everything under ~/.config, for when the thing you need to change "
            .. "isn't Neovim -- sketchybar, aerospace, wezterm and friends.",
        root = "~/.config",
        hide = { "node_modules", "*.log" },
        expand = { "nvim", "sketchybar" },
    },
}
