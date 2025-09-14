return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
        ensure_installed = {
            "lua_ls",
            "gopls",
            "rust_analyzer",
        },
    },
    dependencies = {
        {
            "mason-org/mason.nvim",
            -- Mason doesn't like :setup() being called twice; :setup(opts) is called when dep is loaded
            opts = {
                ui = {
                    border = "single",
                }
            }
        },
        "neovim/nvim-lspconfig",
    },
}
