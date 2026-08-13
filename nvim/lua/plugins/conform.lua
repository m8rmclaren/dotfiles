return {
    'stevearc/conform.nvim',
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")

        conform.setup({
            formatters_by_ft = {
                swift = { "swiftformat" },
                json = { "prettier" },
                markdown = { "prettier_md" },

                -- run gofmt/goimports first, then swag fmt for the annotations
                go = { "goimports", "swag_fmt" },
            },
            format_on_save = {
                -- These options will be passed to conform.format()
                timeout_ms = 2000,
                lsp_format = "fallback", -- LSP formatting is used when no other formatters are available
            },
            formatters = {
                -- prettier with 4-space list indentation; scoped to markdown so
                -- json keeps prettier's default 2-space indent
                prettier_md = require("conform.util").merge_formatter_configs(
                    require("conform.formatters.prettier"),
                    { prepend_args = { "--tab-width", "4" } }
                ),
                swag_fmt = {
                    command = "go",
                    args = { "tool", "swag", "fmt", "--pipe" },
                    -- go tool must resolve inside the module that declares swag
                    cwd = require("conform.util").root_file({ "go.mod" }),
                    -- skip projects that don't declare swag as a go tool
                    condition = function(_, ctx)
                        return vim.fs.find("go.mod", { path = ctx.dirname, upward = true })[1] ~= nil
                    end,
                    stdin = true,
                },
            },
        })
    end,
}
