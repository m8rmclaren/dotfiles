-- Disable copilot globally for all filetypes
vim.g.copilot_filetypes = { ['*'] = false }

-- Remap <M-\> to <leader>s to explicitly ask Copilot for a suggestion
vim.keymap.set('i', '<C-s>', '<Plug>(copilot-suggest)')
