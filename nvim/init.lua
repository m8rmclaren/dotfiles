-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup("plugins")

require("set")
require("remap")

-- return require('packer').startup(function(use)
--     -- Deps
--     use 'wbthomason/packer.nvim'
--     use "nvim-lua/plenary.nvim"

--     -- Telescope
--     use {
--         'nvim-telescope/telescope.nvim', tag = '0.1.5',
--         -- or                            , branch = '0.1.x',
--         requires = { { 'nvim-lua/plenary.nvim' } }
--     }
--     use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

--     -- Navigation
--     use("nvim-tree/nvim-tree.lua")
--     use("alexghergh/nvim-tmux-navigation")
--     use {
--         "ThePrimeagen/harpoon",
--         branch = "harpoon2",
--         requires = { { "nvim-lua/plenary.nvim" } }
--     }

--     -- Editor plumbing
--     use({ 'nvim-treesitter/nvim-treesitter' })
--     -- use("nvim-treesitter/nvim-treesitter-context")
--     use("akinsho/toggleterm.nvim")
--     -- use("airblade/vim-gitgutter")

--     -- Editor niceties
--     use("github/copilot.vim") -- Copilot integration
--     use("mbbill/undotree")    -- undo history visualizer
--     use("tpope/vim-fugitive") -- Git commands in nvim
--     use("lukas-reineke/indent-blankline.nvim")
--     use("windwp/nvim-autopairs")
--     use("tpope/vim-commentary") -- "gc" to comment visual regions/lines
--     use("tpope/vim-surround")

--     -- Theme
--     use { "catppuccin/nvim", as = "catppuccin" }
--     use {
--         'nvim-lualine/lualine.nvim',
--         requires = { 'nvim-tree/nvim-web-devicons', opt = true }
--     }

--     -- LSP
--     use 'hoffs/omnisharp-extended-lsp.nvim'
--     use {
--         'VonHeikemen/lsp-zero.nvim',
--         branch = 'v3.x',
--         requires = {
--             { 'williamboman/mason.nvim' },
--             { 'williamboman/mason-lspconfig.nvim' },

--             -- LSP Support
--             { 'neovim/nvim-lspconfig' },
--             -- Autocompletion
--             { 'hrsh7th/nvim-cmp' },
--             { 'hrsh7th/cmp-nvim-lsp' },
--             { 'L3MON4D3/LuaSnip' },
--         }
--     }
-- end)

-- return require('packer').startup(function(use)
--     -- Packer can manage itself
--     use 'wbthomason/packer.nvim'

--     -- Required by Telescope & Harpoon
--     use "nvim-lua/plenary.nvim"

--     use {
--         'nvim-telescope/telescope.nvim', tag = '0.1.5',
--         -- or                            , branch = '0.1.x',
--         requires = { {'nvim-lua/plenary.nvim'} }
--     }
--     use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

--      use("tpope/vim-commentary") -- "gc" to comment visual regions/lines
--      use("tpope/vim-surround")
--      -- Theme
--      use { "catppuccin/nvim", as = "catppuccin" }

--      -- Statusline
--      use {
--          'nvim-lualine/lualine.nvim',
--          requires = { 'nvim-tree/nvim-web-devicons', opt = true }
--      }

--     -- File explorer
--     use("nvim-tree/nvim-tree.lua")

--     use {
--         "ThePrimeagen/harpoon",
--         branch = "harpoon2",
--         requires = { {"nvim-lua/plenary.nvim"} }
--     }
-- end)
