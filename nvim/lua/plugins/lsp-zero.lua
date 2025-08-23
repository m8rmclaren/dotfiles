return {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    lazy = false,
    dependencies = {
        { 'williamboman/mason.nvim' },
        { 'williamboman/mason-lspconfig.nvim' },

        -- LSP Support
        { 'neovim/nvim-lspconfig' },

        -- Autocompletion
        { 'hrsh7th/nvim-cmp' },
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'hrsh7th/cmp-cmdline' },
        { 'L3MON4D3/LuaSnip' },
    },
    config = function()
        local lsp_zero = require('lsp-zero')
        local cmp = require('cmp')

        lsp_zero.on_attach(function(client, bufnr)
            -- see :help lsp-zero-keybindings
            -- to learn the available actions
            local opts = { buffer = bufnr, remap = false }

            -- virtual_text is off by default in nvim 0.11+
            vim.diagnostic.config({virtual_text=true})

            -- global callbacks for LSP responses are removed in nvim 0.11+, so bordered floating windows must be 
            -- configured manually per invocation
            vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts, { desc = "Code action" })
            vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts, { desc = "Rename under cursor" })
            vim.keymap.set("i", "<C-S>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, opts,
                { desc = "Signature help under cursor" })
            vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts, { desc = "Code action" })
            vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, opts, { desc = "Hover" })

            if vim.bo.filetype == 'cs' then
                local omnisharp_extended = require('omnisharp_extended')

                -- Set keybindings for OmniSharp Extended
                vim.keymap.set("n", "gd", function() omnisharp_extended.telescope_lsp_definition() end, opts)
                -- vim.keymap.set("n", "<leader>fr", omnisharp_extended.telescope_lsp_references, opts)
                vim.keymap.set("n", "<leader>D", omnisharp_extended.telescope_lsp_type_definition, opts)
                vim.keymap.set("n", "gi", omnisharp_extended.telescope_lsp_implementation, opts)
            end

            if client.server_capabilities.documentFormattingProvider then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format({ async = false })
                    end
                })
            end

            lsp_zero.default_keymaps({ buffer = bufnr })
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
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
            }, {
                { name = 'buffer' },
            })
        })

        cmp.setup.cmdline({ '/', '?' }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = 'buffer' }
            }
        })

        -- cmp.setup.cmdline(':', {
        --     mapping = cmp.mapping.preset.cmdline(),
        --     sources = cmp.config.sources({
        --         { name = 'path' }
        --     }, {
        --         { name = 'cmdline' }
        --     }),
        --     matching = { disallow_symbol_nonprefix_matching = false }
        -- })

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

        require('lspconfig').omnisharp.setup({
            enableDecompilationSupport = true,
        })

        require('lspconfig').clangd.setup({
        })
    end
}
