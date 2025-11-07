vim.g.mapleader = " "

----------------------------------
-- Copy and Paste (yank and put) -
----------------------------------

-- Visual mode - Copy to clipboard
vim.api.nvim_set_keymap('v', '<leader>y', '"+y', { noremap = true, desc = 'Copy to clipboard' })

-- Normal mode - Copy to clipboard
vim.api.nvim_set_keymap('n', '<leader>Y', '"+yg_', { noremap = true, desc = 'Copy to clipboard' })
vim.api.nvim_set_keymap('n', '<leader>y', '"+y', { noremap = true, desc = 'Copy to clipboard' })
vim.api.nvim_set_keymap('n', '<leader>yy', '"+yy', { noremap = true, desc = 'Copy to clipboard' })

-- Normal mode - Paste from clipboard
vim.api.nvim_set_keymap('n', '<leader>p', '"+p', { noremap = true, desc = 'Paste from clipboard' })
vim.api.nvim_set_keymap('n', '<leader>P', '"+P', { noremap = true, desc = 'Paste from clipboard' })

-- Visual mode - Paste from clipboard
vim.api.nvim_set_keymap('v', '<leader>p', '"+p', { noremap = true, desc = 'Paste from clipboard' })
vim.api.nvim_set_keymap('v', '<leader>P', '"+P', { noremap = true, desc = 'Paste from clipboard' })

-- Create a newline under the current line
vim.api.nvim_set_keymap('n', '<S-CR>', 'o<Esc>', { noremap = true, desc = 'Create a newline under the current line' })

--------------------
-- Window Controls -
--------------------

-- Increase/decrease height
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { noremap = true, desc = 'Make window taller' })    -- taller
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { noremap = true, desc = 'Make window shorter' }) -- shorter

-- Increase/decrease width
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { noremap = true, desc = 'Make window wider' })   -- wider
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { noremap = true, desc = 'Make window narrower' }) -- narrower
