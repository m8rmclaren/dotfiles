return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",

        -- see below for full list of optional dependencies 👇
    },
    opts = {
        workspaces = {
            {
                name = "work",
                path = "~/Documents/Obsidian Vault",
            },
        },
    },
    config = function()
        vim.opt_local.conceallevel = 2
    end
}
