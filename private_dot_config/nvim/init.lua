local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

---------------------------------------------------------------------
-- 🔥 LAZY SETUP — version correcte
---------------------------------------------------------------------
require("lazy").setup({
    spec = {

        -- Import all plugin files from lua/plugins/*.lua
        { import = "plugins" },

        -----------------------------------------------------------------
        -- Fix JSON
        -----------------------------------------------------------------
        { "rhysd/vim-fixjson", ft = { "json" } },
        { "pseewald/vim-anyfold", ft = { "json" } },

        -----------------------------------------------------------------
        -- Dadbod
        -----------------------------------------------------------------
        {
            "kristijanhusak/vim-dadbod-ui",
            cmd = { "DB", "DBUI", "DBUIToggle", "DBUIFindBuffer", "DBUIRenameBuffer" },
            dependencies = {
                { "tpope/vim-dadbod", lazy = true },
                { "kristijanhusak/vim-dadbod-completion", lazy = true },
            },
            build = function()
                require("patch_dadbod_ui").patch_query_buffer()
            end,
            config = function()
                require("dadbod-dbs").setup_dbs()
                require("dadbod-setup")
            end,
        },

        -----------------------------------------------------------------
        -- LSP + nvim-cmp
        -----------------------------------------------------------------
        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",

        { "mtoohey31/cmp-fish", ft = "fish" },

        -----------------------------------------------------------------
        -- Misc
        -----------------------------------------------------------------
        "numToStr/Comment.nvim",
        { "linux-cultist/venv-selector.nvim", version = "*" },

        -----------------------------------------------------------------
        -- Telescope
        -----------------------------------------------------------------
        "nvim-telescope/telescope.nvim",
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",

        -----------------------------------------------------------------
        -- Colorschemes
        -----------------------------------------------------------------
        "folke/tokyonight.nvim",

        -----------------------------------------------------------------
        -- Treesitter
        -----------------------------------------------------------------
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            opts = {
                ensure_installed = { "fish", "yaml" },
            },
        },

        -----------------------------------------------------------------
        -- Smart splits
        -----------------------------------------------------------------
        {
            "mrjones2014/smart-splits.nvim",
            config = function()
                require("smart-splits-setup")
            end,
        },

        -----------------------------------------------------------------
        -- Other global plugins
        -----------------------------------------------------------------
        "folke/lazy.nvim",
        "dstein64/vim-startuptime",
        "nvim-telescope/telescope-symbols.nvim",
        "xiyaowong/telescope-emoji.nvim",
    },
})
---------------------------------------------------------------------

-- Individual module setups
require("cmp-setup")
require("mason-setup")
require("comment-setup")
require("venv-setup")
require("color-setup")
require("my-smart-move")

vim.opt.mouse = "a"

-- Leader key mappings
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- map("n", "<leader>q", ":q<CR>", opts)

-- vim.keymap.set("i", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("i", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("n", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("n", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })

