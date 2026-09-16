-- `DiffviewOpen` with no rev diffs the working tree against HEAD, which shows
-- only whatever is uncommitted right now. When work lands as a long run of
-- small commits, that hides everything already committed, so <leader>do
-- resolves where this branch forked from its trunk and diffs against that
-- point instead -- one view of everything the branch has changed, committed or
-- not.

-- Tried in this order, but the *nearest* fork point wins, so a branch cut from
-- develop bases on develop rather than on the main it left behind.
local TRUNKS = { "develop", "main", "master", "trunk" }

-- A branch whose trunk has moved on can sit a long way past its fork point;
-- clamp so <leader>do never opens a repo-sized diff.
local MAX_DEPTH = 250

-- On a trunk there is no fork point to find -- the history is continuous -- so
-- the base is whichever of these lands *nearest* HEAD: what has not been pushed
-- yet, or what was committed inside the current work session. Either one tracks
-- "what changed since I sat down" far better than a fixed commit count.
local WORK_WINDOW = "4 hours ago"

-- Last resort, when everything is pushed and nothing is recent.
local FALLBACK_DEPTH = 5

---@param root string directory to run git in
---@return string|nil stdout, trimmed; nil if git failed or the repo said no
local function git(root, ...)
    local args = { "git", "-C", root, ... }
    local ok, res = pcall(function()
        return vim.system(args, { text = true }):wait(2000)
    end)
    if not ok or not res or res.code ~= 0 then
        return nil
    end
    local out = vim.trim(res.stdout or "")
    return out ~= "" and out or nil
end

---@param n number
---@return string "1 commit" / "3 commits"
local function commits(n)
    return ("%d commit%s"):format(n, n == 1 and "" or "s")
end

---@return string|nil repo root, nil when not in a git repo
local function repo_root()
    -- Prefer the buffer's own directory so the diff follows the file you are
    -- looking at, not whatever cwd happens to be.
    local dir = vim.fn.expand("%:p:h")
    if dir == "" or vim.fn.isdirectory(dir) == 0 then
        dir = vim.fn.getcwd()
    end
    return git(dir, "rev-parse", "--show-toplevel")
end

---@param root string
---@param branch string|nil
---@return boolean true when HEAD is a trunk branch, i.e. has no fork point
local function on_trunk(root, branch)
    if not branch or branch == "HEAD" then
        return false -- detached: still worth looking for a fork point
    end
    if vim.tbl_contains(TRUNKS, branch) then
        return true
    end
    -- Whatever this remote calls its default branch, e.g. "origin/main".
    local default = git(root, "rev-parse", "--abbrev-ref", "origin/HEAD")
    return default ~= nil and default:gsub("^[^/]+/", "") == branch
end

---Where this branch left its trunk.
---@param root string
---@return string|nil sha, string|nil trunk ref, number|nil commits since
local function fork_point(root)
    local best_sha, best_ref, best_count
    local refs = {}
    local default = git(root, "rev-parse", "--abbrev-ref", "origin/HEAD")
    if default then
        table.insert(refs, default)
    end
    for _, name in ipairs(TRUNKS) do
        table.insert(refs, name)
        table.insert(refs, "origin/" .. name)
    end

    for _, ref in ipairs(refs) do
        if git(root, "rev-parse", "--verify", "--quiet", ref .. "^{commit}") then
            local sha = git(root, "merge-base", "HEAD", ref)
            local count = sha and tonumber(git(root, "rev-list", "--count", sha .. "..HEAD"))
            -- count == 0 means HEAD is at or behind this trunk: no branch work
            -- to show, so keep looking.
            if count and count > 0 and (not best_count or count < best_count) then
                best_sha, best_ref, best_count = sha, ref, count
            end
        end
    end

    return best_sha, best_ref, best_count
end

---How far back a candidate base sits, or nil when it is not usable.
---@param root string
---@param rev string|nil
---@return number|nil
local function distance(root, rev)
    if not rev then
        return nil
    end
    local count = tonumber(git(root, "rev-list", "--count", rev .. "..HEAD"))
    -- 0 means the candidate *is* HEAD: nothing to show, so it is no candidate.
    if not count or count == 0 then
        return nil
    end
    return count
end

---The base for a trunk branch: the nearest of "not yet pushed" and "committed
---this session", so a day of small commits does not drown the view.
---@param root string
---@return string|nil rev, string|nil label
local function session_base(root)
    local best_rev, best_label, best_count

    ---@param rev string|nil
    ---@param describe fun(count: number): string
    local function consider(rev, describe)
        local count = distance(root, rev)
        if count and (not best_count or count < best_count) then
            best_rev, best_label, best_count = rev, describe(count), count
        end
    end

    local upstream = git(root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}")
    consider(upstream and git(root, "merge-base", "HEAD", upstream), function(count)
        return ("%s not pushed to %s"):format(commits(count), upstream)
    end)

    -- The newest commit older than the window: everything after it is this
    -- session's work.
    consider(git(root, "rev-list", "-1", "--before=" .. WORK_WINDOW, "HEAD"), function(count)
        return ("%s in the last %s"):format(commits(count), (WORK_WINDOW:gsub(" ago$", "")))
    end)

    return best_rev, best_label
end

---Last resort: a small fixed window of recent commits.
---@param root string
---@return string|nil rev, number|nil depth
local function recent(root)
    local total = tonumber(git(root, "rev-list", "--count", "HEAD"))
    if not total or total < 2 then
        return nil
    end
    local depth = math.min(FALLBACK_DEPTH, total - 1)
    return "HEAD~" .. depth, depth
end

---Open Diffview against the start of the current branch's work.
local function open_branch_diff()
    local root = repo_root()
    if not root then
        vim.notify("Diffview: not in a git repo", vim.log.levels.WARN)
        return
    end

    local branch = git(root, "rev-parse", "--abbrev-ref", "HEAD")
    local rev, label

    if not on_trunk(root, branch) then
        local sha, ref, count = fork_point(root)
        if sha then
            if count > MAX_DEPTH then
                -- Too far from the trunk to be a useful review; show the tail.
                rev = "HEAD~" .. MAX_DEPTH
                label = ("last %s (fork from %s is %d back)"):format(commits(MAX_DEPTH), ref, count)
            else
                rev = sha
                label = ("%s since %s"):format(commits(count), ref)
            end
        end
    end

    if not rev then
        rev, label = session_base(root)
    end

    if not rev then
        local fallback, depth = recent(root)
        if not fallback then
            -- Root commit, or a repo with nothing to compare against.
            require("diffview").open()
            return
        end
        rev, label = fallback, "last " .. commits(depth)
    end

    vim.notify("Diffview: " .. label, vim.log.levels.INFO)
    require("diffview").open(rev)
end

return {
    "sindrets/diffview.nvim",
    opts = {
        hooks = {
            diff_buf_win_enter = function(bufnr, winid)
                vim.opt_local.foldenable = false
            end,
        },
    },
    keys = {
        { "<leader>do", open_branch_diff,                           desc = "Diffview open (branch base)" },
        { "<leader>dO", function() require("diffview").open() end,  desc = "Diffview open (working tree)" },
        { "<leader>dc", function() require("diffview").close() end, desc = "Diffview close" },
    },
}
