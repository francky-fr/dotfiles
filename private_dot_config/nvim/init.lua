local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
	"git",
	"clone",
	"--filter=blob:none",
	"https://github.com/folke/lazy.nvim.git",
	"--branch=stable", -- latest stable release
	lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "


require("lazy").setup({

	-- Fix JSON
	{ "rhysd/vim-fixjson", ft = { "json" } },
	{ "pseewald/vim-anyfold", ft = { "json" } },

	-- Dadbod
	{
		"kristijanhusak/vim-dadbod-ui",
		cmd = { "DB", "DBUI", "DBUIToggle", "DBUIFindBuffer", "DBUIRenameBuffer" },
		dependencies = {
			{
				"tpope/vim-dadbod",
				lazy = true,
			},
			{
				"kristijanhusak/vim-dadbod-completion",
				lazy = true,
			}
		},
		build = function()
			require("patch_dadbod_ui").patch_query_buffer()
		end,
		config = function()
			require("dadbod-dbs").setup_dbs()
			require("dadbod-setup")
		end,
	},

	-- LSP and completion
	"neovim/nvim-lspconfig",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"hrsh7th/nvim-cmp",
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	{
		"mtoohey31/cmp-fish",
		ft = "fish",
	},


	-- Miscellaneous
	"numToStr/Comment.nvim",
	{ "linux-cultist/venv-selector.nvim", version = "*" },

	-- Telescope
	"nvim-telescope/telescope.nvim",
	"nvim-lua/popup.nvim",
	"nvim-lua/plenary.nvim",

	-- Colorschemes
	"folke/tokyonight.nvim",
	-- "ellisonleao/gruvbox.nvim",
	-- "navarasu/onedark.nvim",
	-- { "catppuccin/nvim", name = "catppuccin" },
	-- "shaunsingh/nord.nvim",
	-- "sainnhe/everforest",

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = { "fish", "yaml" }
		}
	},

	-- Windows
	{
		"mrjones2014/smart-splits.nvim",
		config = function()
			require("smart-splits-setup")
		end,
	},

	"folke/lazy.nvim",

	"dstein64/vim-startuptime",

	-- emojis
	"nvim-telescope/telescope-symbols.nvim",
	"xiyaowong/telescope-emoji.nvim",

	-- llm
	-- {
	-- 	"olimorris/codecompanion.nvim",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-treesitter/nvim-treesitter",
	-- 	},
	-- 	config = function()
	-- 		require("codecompanion").setup()
	-- 	end,
	-- }
	--{ Deprecié le 12/11/2025 car warning, voir avec chatgpt pour la résolution
		--"olimorris/codecompanion.nvim",
		--dependencies = {
			--"nvim-lua/plenary.nvim",
			--"nvim-treesitter/nvim-treesitter",
		--},
		--opts = {
			---- on force l'adapter OpenAI-compatible pointé sur LiteLLM
			--adapters = {
				--bedrock_openai = function()
					--return require("codecompanion.adapters").extend("openai_compatible", {
						--env = {
							--url = "http://127.0.0.1:4000",  -- LiteLLM proxy
							--api_key = "dummy",              -- requis par le schéma OpenAI; valeur quelconque
						--},
						--headers = {
							--["Authorization"] = "Bearer ${api_key}",
							--["Content-Type"] = "application/json",
						--},
						---- modèle "virtuel" vu par LiteLLM (nom côté model_list)
						--schema = {
							--model = { default = "opus-41" },
						--},
					--})
				--end,
				--opts = {
					---- Optionnel: ne montrer que tes adapters custom dans l'UI
					--show_defaults = false,
					--show_model_choices = false,
				--},
			--},
			--strategies = {
				--chat =   { adapter = "bedrock_openai" },
				--inline = { adapter = "bedrock_openai" },
				--cmd =    { adapter = "bedrock_openai" },
			--},
			---- Debug utile si souci:
			--opts = { log_level = "INFO" }, -- "DEBUG" pour plus de détails
		--},
	--}
})

-- Setup per module
require('cmp-setup')
require('mason-setup')
require('comment-setup')
require('venv-setup')
require('color-setup')
require('my-smart-move')

vim.opt.mouse = "a"

-- Leader key mappings in Lua
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map('n', '<leader>q', ':q<CR>', opts)

--vim.keymap.set("i", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
--vim.keymap.set("i", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })
--vim.keymap.set("n", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
--vim.keymap.set("n", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })

