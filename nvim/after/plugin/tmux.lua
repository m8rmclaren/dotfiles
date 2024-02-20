local nvim_tmux_nav = require('nvim-tmux-navigation')

vim.keymap.set('n', "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft, { desc = "Navigate to the pane to the left" })
vim.keymap.set('n', "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown, { desc = "Navigate to the pane below" })
vim.keymap.set('n', "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp, { desc = "Navigate to the pane above" })
vim.keymap.set('n', "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight, { desc = "Navigate to the pane to the right" })
vim.keymap.set('n', "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive, { desc = "Navigate to the last active pane" })
