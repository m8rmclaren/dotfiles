return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'hrsh7th/cmp-buffer' },
        { 'hrsh7th/cmp-path' },
        { 'hrsh7th/cmp-cmdline' },
        { 'L3MON4D3/LuaSnip' },
    },
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')

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

                -- Super-tab behavior
                -- - If the completion window is open, pressing tab selects the next item in the list.
                -- - If tab is pressed over a snippet, the snippet will expand, and continuing to press tab moves the cursor to the next selection point.
                -- - If neither code completing nor expanding a snippet, it will behave like a normal tab key.
                ["<tab>"] = cmp.mapping(function(original)
                    if cmp.visible() then
                        cmp.select_next_item()   -- run completion selection if completing
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump() -- expand snippets
                    else
                        original()               -- run the original behavior if not completing
                    end
                end, { "i", "s" }),
                ["<S-tab>"] = cmp.mapping(function(original)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.jump(-1)
                    else
                        original()
                    end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources {
                { name = "nvim_lsp" },
                { name = "buffer" },
                { name = "path" },
            },
            snippets = {
                expand = function(args)
                    luasnip.lsp_expand(args)
                end,
            },
        })

        cmp.setup.cmdline({ '/', '?' }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = 'buffer' }
            }
        })
    end
}
