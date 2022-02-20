local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer. Restart neovim."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand to reload neovim whener you save this file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

return packer.startup(function(use)
  -- Plugins go here
  use "wbthomason/packer.nvim" -- Have packer manage itself
  use "nvim-lua/popup.nvim" -- An implementation of the popup api from vim in neovim
  use "nvim-lua/plenary.nvim" -- Useful lua functions used by lots of plugins
  -- NOTE (jpd): I'm not sure what's great
  use "windwp/nvim-autopairs" -- Autopair for begin/end of a block
  use {
    "numToStr/Comment.nvim",
    requires = { "JoosepAlviste/nvim-ts-context-commentstring" }, -- Set commentstring opotion based on treesitter
  } -- Easily comment stuff
  use {
    "kyazdani42/nvim-tree.lua",
    requires = { "kyazdani42/nvim-web-devicons" },
  } -- Better alternative for netwr
  use "nvim-lualine/lualine.nvim" -- Blazing fast status line
  use {
    "akinsho/bufferline.nvim",
    requires = { "moll/vim-bbye" },
  } -- Show buffer as tabs
  use "akinsho/toggleterm.nvim" -- Execute terminals inside neovim

  -- colorscheme
  use "folke/tokyonight.nvim"           -- An amazing theme

  -- completion (cmp) plugins
  use "hrsh7th/nvim-cmp" -- Completion engine plugin
  use "hrsh7th/cmp-buffer" -- buffer completions
  use "hrsh7th/cmp-path" -- path completions
  use "hrsh7th/cmp-cmdline" -- command line completions
  use "saadparwaiz1/cmp_luasnip" -- snippet completions
  use "hrsh7th/cmp-nvim-lsp" -- lsp completions
  use "hrsh7th/cmp-nvim-lua" -- nvim lua completions

  -- snippets plugins
  use "L3MON4D3/LuaSnip" -- Snippet engine plugin
  use "rafamadriz/friendly-snippets" -- bunch of snippets to use

  -- LSP
  use "neovim/nvim-lspconfig" -- Easier LSP configuration
  use "williamboman/nvim-lsp-installer" -- simple to use lsp installer

  -- Telescope
  use "nvim-telescope/telescope.nvim" -- Smartest fuzzy finder

  -- Treesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }

  -- git
  use "lewis6991/gitsigns.nvim" -- Show hints from git in the editor
  use "tpope/vim-fugitive"
  use {
    "joaodubas/gitlinker.nvim",
    requires = { "nvim-lua/plenary.nvim" },
  }

  -- Automatically set up your configuration after cloning packer.nvim
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
