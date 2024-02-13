local toggleterm = require("toggleterm")
local Terminal  = require('toggleterm.terminal').Terminal

toggleterm.setup()

local workspace_focus_terminal = Terminal:new({
    cmd = "zsh",
    direction = "float",
    float_opts = {
        border = "single",
    },
    on_open = function(term)
        vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<esc>", "<C-\\><C-n>", {noremap = true, silent = true})
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<esc>", "<C-w>q", {noremap = true, silent = false}) -- I have no idea why adding a j here makes it work but it does
    end
})

local function toggle_focused_terminal()
    workspace_focus_terminal:toggle()
    workspace_focus_terminal:set_mode("i")
end

vim.keymap.set("n", "<leader>tt", function() toggle_focused_terminal() end)
