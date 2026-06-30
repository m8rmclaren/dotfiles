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
        { "<leader>do", function() require("diffview").open() end,  desc = "Diffview open" },
        { "<leader>dc", function() require("diffview").close() end, desc = "Diffview close" },
    },
}
