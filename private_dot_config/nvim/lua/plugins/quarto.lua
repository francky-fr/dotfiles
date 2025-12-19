return {

  ---------------------------------------------------------------------------
  -- 1) Quarto
  ---------------------------------------------------------------------------
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto", "markdown" , "go"},

    config = function()
      -----------------------------------------------------------------------
      -- Initialisation Quarto (OBLIGATOIRE)
      -----------------------------------------------------------------------
      require("quarto").setup({
        lspFeatures = {
          enabled = true,
          chunks = "curly",
        },
        codeRunner = {
          enabled = true,
          default_method = "slime",
        },
      })

      -----------------------------------------------------------------------
      -- Mapping pour envoyer la cellule courante
      -----------------------------------------------------------------------
      vim.keymap.set("n", "<C-e>", "<cmd>QuartoSend<CR>", {
        desc = "Quarto: Send current cell",
        silent = true,
      })
    end,

    dependencies = {
      "jmbuhr/otter.nvim",
      "jpalardy/vim-slime",
    },
  },

  ---------------------------------------------------------------------------
  -- 2) Jupytext (ouvrir .ipynb en Quarto)
  ---------------------------------------------------------------------------
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
        r = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- 3) Slime (envoyer code au REPL)
  ---------------------------------------------------------------------------
  {
	  "jpalardy/vim-slime",

	  init = function()
		  -- vim.g.slime_target = "neovim"
		  vim.g.slime_target = "tmux"
		  vim.g.slime_default_config = {
			  -- target_pane = "go-repl-lab:repls.0",
			  -- target_pane = "go-repl-lab:repls.2",
			  -- target_pane = "go-repl-lab:yaegi-A.0",
			  -- target_pane = "go-repl-lab:gomacro-A.0",
			  target_pane = "go-repl-lab:yaegi-B.0",
			  socket_name = "default",
		  }
		  vim.g.slime_dont_ask_default = 1
		  vim.g.slime_no_mappings = true
		  vim.g.slime_bracketed_paste = 1
	  end,

	  config = function()

		  vim.keymap.set("v", "rr", "<Plug>SlimeRegionSend", { silent = true })
		  vim.keymap.set("n", "rr", "<Plug>SlimeLineSend", { silent = true })
		  vim.keymap.set("n", "rf", ":%SlimeSend<CR>", { silent = true })
		  vim.keymap.set("n", "r", "<nop>", { noremap = true })

	  end,
  },

  ---------------------------------------------------------------------------
  -- 4) Coller facilement des images
  ---------------------------------------------------------------------------
  {
    "HakonHarnes/img-clip.nvim",
    event = "BufEnter",
    ft = { "markdown", "quarto", "latex" },
    opts = {
      default = {
        dir_path = "img",
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = "![$CURSOR]($FILE_PATH)",
          drag_and_drop = { download_images = false },
        },
        quarto = {
          url_encode_path = true,
          template = "![$CURSOR]($FILE_PATH)",
          drag_and_drop = { download_images = false },
        },
      },
    },
    config = function(_, opts)
      require("img-clip").setup(opts)
      vim.keymap.set("n", "<leader>ii", ":PasteImage<CR>", {
        desc = "Insert image from clipboard",
        silent = true,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- 5) Nabla (render math inline)
  ---------------------------------------------------------------------------
  {
    "jbyuki/nabla.nvim",
    keys = {
      {
        "<leader>qm",
        ':lua require("nabla").toggle_virt()<CR>',
        desc = "Toggle math preview",
      },
    },
  },

}

