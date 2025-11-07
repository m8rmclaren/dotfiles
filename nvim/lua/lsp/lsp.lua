vim.diagnostic.config({
    -- virtual_text is off by default in nvim 0.11+
    -- virtual_text = true,

    -- virtual_lines was upstreamed from lsp_lines.nvim to nvim 0.11+
    virtual_lines = true,
    float = { border = "rounded" },
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        -- LSP actions
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', 'K', function() vim.lsp.buf.hover { border = 'rounded' } end, opts)
        vim.keymap.set('i', '<C-S>', function() vim.lsp.buf.signature_help { border = 'rounded' } end, opts)

        -- Language-specific bindings
        if vim.bo[ev.buf].filetype == 'cs' then
            local omni = require('omnisharp_extended')
            vim.keymap.set('n', 'gd', omni.telescope_lsp_definition, opts)
            vim.keymap.set('n', '<leader>D', omni.telescope_lsp_type_definition, opts)
            vim.keymap.set('n', 'gi', omni.telescope_lsp_implementation, opts)
        end

        -- Don't let ts_ls & denols compete; stop TS clients that have no root_dir
        local clients = vim.lsp.get_clients({ bufnr = ev.buf })
        local typescript_clients = { ts_ls = true, denols = true }

        for _, client in pairs(clients) do
            if typescript_clients[client.name] then
                local has_root = client.config and client.config.root_dir and client.config.root_dir ~= ""
                if not has_root then
                    client:stop() -- method form replaces deprecated client.stop()
                end
            end
        end
    end,
})

-- LSPs to manually config
vim.lsp.config.clangd = {
    cmd = {
        "clangd",
        "--query-driver=/Applications/ArmGNUToolchain/14.3.rel1/arm-none-eabi/bin/arm-none-eabi-*", -- allow querying the cross GCC
        "--background-index",
    },
}

vim.lsp.config.omnisharp = {
    enableDecompilationSupport = true,
}

vim.lsp.config.lua_ls = {
    settings = {
        Lua = {
            diagnostics = {
                -- tell the language server to recognize the `vim` global
                globals = { "vim" },
            },
        },
    }
}

vim.lsp.config.sourcekit = {
    capabilities = {
        workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
    },
}

vim.lsp.config.denols = {
    root_markers = { "deno.json", "deno.jsonc" },
    single_file_support = false,
    settings = {},
}

vim.lsp.config.ts_ls = {
    root_markers = { "package.json" },
    single_file_support = false,
}

-- LSPs to manually enable (IE not automatically enabled by mason-lspconfig)
vim.lsp.enable({ 'clangd' })
vim.lsp.enable({ 'sourcekit' })
