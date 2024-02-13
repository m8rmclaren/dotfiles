local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

-- This file can be loaded by calling `lua require('plugins')` from your init.vim

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- Required by Telescope & Harpoon
    use "nvim-lua/plenary.nvim"

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        -- or                            , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} }
    }
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

    use({'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'})
    use("github/copilot.vim") -- Copilot integration
    use("tpope/vim-fugitive") -- Git commands in nvim
    use("nvim-treesitter/nvim-treesitter-context")
    use("mbbill/undotree") -- undo history visualizer
    use("tpope/vim-commentary") -- "gc" to comment visual regions/lines
    use("lukas-reineke/indent-blankline.nvim")
    use("windwp/nvim-autopairs")
    use("alexghergh/nvim-tmux-navigation")
    use("akinsho/toggleterm.nvim")

    use("ThePrimeagen/vim-be-good")

    -- Theme
    use { "catppuccin/nvim", as = "catppuccin" }
    use({
        'rose-pine/neovim',
        as = 'rose-pine'
    })

    -- Statusline
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }

    -- File explorer
    use("nvim-tree/nvim-tree.lua")

    use {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        requires = { {"nvim-lua/plenary.nvim"} }
    }

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            --- Uncomment the two plugins below if you want to manage the language servers from neovim
            --- and read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            -- LSP Support
            {'neovim/nvim-lspconfig'},
            -- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        }
    }

    if packer_bootstrap then
        require('packer').sync()
    end
end)


