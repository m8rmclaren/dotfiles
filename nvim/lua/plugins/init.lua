return {
    -- Editor niceties
    "tpope/vim-fugitive",   -- Git commands in nvim
    -- "lukas-reineke/indent-blankline.nvim",
    "tpope/vim-commentary", -- "gc" to comment visual regions/lines
    -- "tpope/vim-surround",

    -- LSP
    'hoffs/omnisharp-extended-lsp.nvim',

    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },
    -- automatically check for plugin updates
    checker = { enabled = true },
}
