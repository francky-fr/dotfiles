return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  opts = {
    provider = "openai",
    providers = {
      openai = {
        endpoint = "http://localhost:8666/v1",
        model = "qwen2.5-coder-14b",
        api_key_name = "OPENAI_API_KEY",
        timeout = 30000,
      },
    },
    behaviour = {
      auto_suggestions = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },
    mappings = {
      ask = "<leader>aa",
      edit = "<leader>ae",
      refresh = "<leader>ar",
    },
  },
  config = function(_, opts)
    -- On initialise Avante avec tes opts
    require("avante").setup(opts)

    -- On ajoute le mapping personnalisé pour vider le chat
    -- <cmd>AvanteClear<cr> nettoie l'historique de la session actuelle
    vim.keymap.set("n", "<leader>ac", "<cmd>AvanteClear<cr>", { desc = "Avante: Clear Chat" })
  end,
  build = "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
