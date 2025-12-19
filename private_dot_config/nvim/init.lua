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
-- vim.opt.mouse = ""
vim.opt.mouse = "a"

require("lazy").setup({
    spec = {

        { import = "plugins" },

        { "rhysd/vim-fixjson", ft = { "json" } },
        { "pseewald/vim-anyfold", ft = { "json" } },

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

        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
	"hrsh7th/vim-vsnip",
	"hrsh7th/vim-vsnip-integ",
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",

        { "mtoohey31/cmp-fish", ft = "fish" },

        "numToStr/Comment.nvim",
        { "linux-cultist/venv-selector.nvim", version = "*" },

        "nvim-telescope/telescope.nvim",
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",

        "folke/tokyonight.nvim",

        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            opts = {
                ensure_installed = { "fish", "yaml" },
            },
        },

        {
            "mrjones2014/smart-splits.nvim",
            config = function()
                require("smart-splits-setup")
            end,
        },

        "folke/lazy.nvim",
        "dstein64/vim-startuptime",
        "nvim-telescope/telescope-symbols.nvim",
        "xiyaowong/telescope-emoji.nvim",

	{
		"mfussenegger/nvim-dap",
		config = function()
			require("dap-setup")
		end,
	},
	-- {
	-- 	"leoluz/nvim-dap-go",
	-- 	ft = "go",
	-- 	dependencies = { "mfussenegger/nvim-dap" },
	-- 	config = function()
	-- 		require("dap-go").setup()
	-- 	end,
	-- },
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-go").setup({
				-- Désactive les optimisations pour un meilleur debug
				delve = {
					-- Chemin vers delve (optionnel si dans PATH)
					path = "dlv",
					-- Arguments de build
					initialize_timeout_sec = 20,
					port = "${port}",
					args = {},
					build_flags = "-gcflags='all=-N -l'",
				},
				-- Configuration des types de debug
				dap_configurations = {
					{
						type = "go",
						name = "Debug",
						request = "launch",
						program = "${file}",
					},
					{
						type = "go",
						name = "Debug Package",
						request = "launch",
						program = "${fileDirname}",
					},
					{
						type = "go",
						name = "Debug Test",
						request = "launch",
						mode = "test",
						program = "${file}",
					},
				},
			})
		end,
	},
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("snacks").setup({
				input = {
					enabled = true,
					history = true,
					prompt_pos = "top",
					win = {
						relative = "cursor",
						row = 1,
						col = 0,
					},
				},
				select = {
					enabled = true,
				},
			})
			vim.ui.input = require("snacks.input").input
		end,
	},
	{
		"farmergreg/vim-lastplace",
		event = "BufReadPost",
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			require("dapui").setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.45 },
							{ id = "watches", size = 0.25 },
							{ id = "stacks", size = 0.15 },
							{ id = "breakpoints", size = 0.15 },
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							"repl",
							"console",
						},
						size = 0.25,
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl",
				},
				floating = {
					border = "rounded",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})
		end,
	}


},

})
---------------------------------------------------------------------

require("cmp-setup")
require("mason-setup")
require("comment-setup")
require("venv-setup")
require("color-setup")
require("my-smart-move")
require("lsp-setup")

-- Leader key mappings
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }


vim.api.nvim_create_user_command("GoKernel", function()
  vim.cmd("vsplit")
  vim.cmd("wincmd l")
  vim.cmd("terminal gomacro")
  vim.w.is_go_repl = true
  vim.cmd("wincmd h") -- revient sur la fenêtre source
end, { desc = "Start Go kernel (gomacro)" })

vim.api.nvim_create_user_command("GoTemp", function()
  local filename = "/tmp/tmp_" .. os.date("%Y%m%d_%H%M%S") .. ".go"
  vim.cmd("belowright split " .. filename)
  vim.bo.filetype = "go"
end, { desc = "Open temp Go file in bottom split (/tmp)" })


-- Toujours scroller le terminal à la dernière ligne
vim.api.nvim_create_autocmd({ "TermOpen", "TermEnter" }, {
  callback = function()
    vim.cmd("normal! G")
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    local total = vim.o.columns
    local target = math.floor(total * 0.5)

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.w[win].is_go_repl then
        vim.api.nvim_win_call(win, function()
          vim.cmd("vertical resize " .. target)
        end)
      end
    end
  end,
})

vim.keymap.set("n", "dp", function()
  require("dap.ui.widgets").hover()
end, { desc = "DAP: print variable under cursor" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-float",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = true,
      silent = true,
    })
  end,
})


-- vim.keymap.set("n", "<leader>kg", function()
--   vim.cmd("vsplit")
--   vim.cmd("wincmd l")
--   vim.cmd("terminal gomacro")
--   vim.cmd("wincmd h")
-- end, { desc = "Start Go kernel (gomacro)" })
--
-- vim.keymap.set("n", "<leader>kt", function()
--   local filename = "/tmp/tmp_" .. os.date("%Y%m%d_%H%M%S") .. ".go"
--   vim.cmd("belowright split " .. filename)
--   vim.bo.filetype = "go"
-- end, { desc = "Open temp Go file in bottom split (/tmp)" })


-- map("n", "<leader>q", ":q<CR>", opts)

-- vim.keymap.set("i", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("i", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("n", "<leader>e", "<Cmd>Telescope emoji<CR>", { desc = "Insert emoji" })
-- vim.keymap.set("n", "<leader>s", "<Cmd>Telescope symbols<CR>", { desc = "Insert emoji" })
