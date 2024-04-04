local lsp_zero = require('lsp-zero')
local cmp = require('cmp')

lsp_zero.on_attach(function(client, bufnr)
    -- see :help lsp-zero-keybindings
    -- to learn the available actions
    local opts = {buffer = bufnr, remap = false}

    -- vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    -- vim.keymap.set("n", "gb", "<C-o>", opts)
    vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts, { desc = "Code action" })
    vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts, { desc = "Rename under cursor" })
    vim.keymap.set("n", "<leader>s", function() vim.lsp.buf.hover() end, opts, { desc = "Show hover information" })

    lsp_zero.default_keymaps({buffer = bufnr})
end)

cmp.setup({
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        -- confirm completion
        ['<Enter>'] = cmp.mapping.confirm({ select = true }),

        -- scroll up and down the documentation window
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
    }),
})

-- here you can setup the language servers

require('mason').setup({})
require('mason-lspconfig').setup({
    -- Replace the language servers listed here 
    -- with the ones you want to install
    ensure_installed = {},

    automatic_installation = true,

    handlers = {
        lsp_zero.default_setup,
    },
})


