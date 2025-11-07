return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
        ensure_installed = {
            "lua_ls",

            -- Go
            "gopls",
            "templ",

            -- Rust
            "rust_analyzer",

            -- Typescript/Javascript
            "denols",
            "ts_ls",
            "eslint",
            "tailwindcss",

            -- JSON
            "jsonls",

            -- Terraform
            "terraformls",
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
