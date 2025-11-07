return {
    "rcarriga/nvim-dap-ui",
    dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio",
        "nvim-telescope/telescope-dap.nvim",
    },
    lazy = true,
    config = function()
        require("dapui").setup({
            controls = {
                element = "repl",
                enabled = true,
            },
            floating = {
                border = "single",
                mappings = {
                    close = { "q", "<Esc>" },
                },
            },
            icons = { collapsed = "", expanded = "", current_frame = "" },
            layouts = {
                {
                    elements = {
                        { id = "stacks",      size = 0.25 },
                        { id = "scopes",      size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "watches",     size = 0.25 },
                    },
                    position = "left",
                    size = 60,
                },
                {
                    elements = {
                        { id = "repl",    size = 0.35 },
                        { id = "console", size = 0.65 },
                    },
                    position = "bottom",
                    size = 10,
                },
            },
        })

        local dap, dapui = require("dap"), require("dapui")

        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- Try to break on exceptions/signals (adapter support varies)
        -- Will stop on things like SIGSEGV if the adapter supports it.
        pcall(function() dap.set_exception_breakpoints({ "all" }) end)

        -- Jump through stack frames easily, which opens the file/line.
        local widgets = require("dap.ui.widgets")
        vim.keymap.set("n", "<leader>df", function()
            widgets.centered_float(widgets.frames)
        end, { desc = "DAP: frames" })

        -- Telescope pickers for frames/variables/breakpoints
        require("telescope").load_extension("dap")
        vim.keymap.set("n", "<leader>dF", function() require("telescope").extensions.dap.frames() end,
            { desc = "DAP: frames (Telescope)" })
    end,
}
