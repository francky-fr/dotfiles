return {

  -- 1) Quarto
  {
    'quarto-dev/quarto-nvim',
    opts = {
      lspFeatures = {
        enabled = true,
        chunks = 'curly',
      },
      codeRunner = {
        enabled = true,
        default_method = 'slime',
      },
    },
    config = function()
      vim.keymap.set("n", "<C-e>", "<cmd>QuartoSend<CR>", {
        desc = "Quarto: Send current cell",
      })
    end,
    dependencies = {
      'jmbuhr/otter.nvim',
      'jpalardy/vim-slime',
    },
  },

  -- 2) Jupytext
  {
    'GCBallesteros/jupytext.nvim',
    opts = {
      custom_language_formatting = {
        python = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
        r = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
      },
    },
  },

  -- 3) Slime
  {
    'jpalardy/vim-slime',
    init = function()
      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_bracketed_paste = 1
    end,
  },

  -- 4) img-clip
  {
    'HakonHarnes/img-clip.nvim',
    event = 'BufEnter',
    ft = { 'markdown', 'quarto', 'latex' },
    opts = {
      default = { dir_path = 'img' },
    },
    config = function(_, opts)
      require('img-clip').setup(opts)
      vim.keymap.set('n', '<leader>ii', ':PasteImage<cr>')
    end,
  },

  -- 5) Nabla
  {
    'jbyuki/nabla.nvim',
    keys = {
      { '<leader>qm', ':lua require"nabla".toggle_virt()<cr>' },
    },
  },
}

