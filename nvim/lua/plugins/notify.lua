return {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 900,
    config = function()
        local notify = require("notify")

        notify.setup({
            background_colour = "#000000",
            fps = 60,
            render = "compact",
            stages = "fade",
            timeout = 3000,
            top_down = true,
        })

        vim.notify = notify

        vim.lsp.handlers["window/showMessage"] = function(_, result, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            local level = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
            vim.notify(result.message, vim.log.levels[level], {
                title = "LSP | " .. (client and client.name or "unknown"),
            })
        end
    end,
}
