vim.g.mapleader = " "
-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Copy and Paste (yank and put)

-- Visual mode - Copy to clipboard
vim.api.nvim_set_keymap('v', '<leader>y', '"+y', { noremap = true })

-- Normal mode - Copy to clipboard
vim.api.nvim_set_keymap('n', '<leader>Y', '"+yg_', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>y', '"+y', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>yy', '"+yy', { noremap = true })

-- Normal mode - Paste from clipboard
vim.api.nvim_set_keymap('n', '<leader>p', '"+p', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>P', '"+P', { noremap = true })

-- Visual mode - Paste from clipboard
vim.api.nvim_set_keymap('v', '<leader>p', '"+p', { noremap = true })
vim.api.nvim_set_keymap('v', '<leader>P', '"+P', { noremap = true })

-- vim.api.nvim_set_keymap('n', '<leader>wv', '<C-w>v', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>ws', '<C-w>s', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>wh', '<C-w>h', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>wj', '<C-w>j', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>wk', '<C-w>k', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>wl', '<C-w>l', {noremap = true, silent = true})
-- vim.api.nvim_set_keymap('n', '<leader>wc', '<C-w>c', {noremap = true, silent = true})
