return {
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto", "markdown" },
    config = function()
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

      vim.keymap.set("n", "<leader>qp", function()
        local file = vim.fn.expand("%:p")
        vim.fn.jobstart({ "uv", "run", "quarto", "preview", file }, {
          detach = true,
          cwd = vim.fn.fnamemodify(file, ":h"),
        })
        vim.notify("Quarto preview lancé", vim.log.levels.INFO)
      end, { desc = "Quarto: preview", silent = true })

      vim.keymap.set("n", "<leader>qr", function()
        local file = vim.fn.expand("%:p")
        vim.fn.jobstart({ "uv", "run", "quarto", "render", file }, {
          cwd = vim.fn.fnamemodify(file, ":h"),
        })
        vim.notify("Quarto render…", vim.log.levels.INFO)
      end, { desc = "Quarto: render", silent = true })

      vim.keymap.set("n", "<leader>qR", function()
        local file = vim.fn.expand("%:p")
        vim.fn.jobstart({ "uv", "run", "quarto", "render", file, "--cache-refresh" }, {
          cwd = vim.fn.fnamemodify(file, ":h"),
        })
        vim.notify("Quarto render forcé (cache vidé)…", vim.log.levels.INFO)
      end, { desc = "Quarto: render forcé", silent = true })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "quarto" },
        callback = function()
          -- <C-s> : envoie la cellule courante → IPython
          vim.keymap.set("n", "<C-s>", "<cmd>QuartoSend<CR>", {
            buffer = true,
            desc   = "Quarto: envoie la cellule → IPython",
            silent = true,
          })
          -- ss : envoie la ligne courante → IPython
          vim.keymap.set("n", "ss", "<Plug>SlimeLineSend", {
            buffer = true,
            desc   = "Quarto: envoie la ligne → IPython",
            silent = true,
          })
        end,
      })
    end,
    dependencies = {
      "jmbuhr/otter.nvim",
      "jpalardy/vim-slime",
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
      },
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "BufEnter",
    ft = { "markdown", "quarto", "latex" },
    opts = {
      default = { dir_path = "img" },
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
