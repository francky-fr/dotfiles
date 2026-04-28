return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local adapters = require("codecompanion.adapters")

    require("codecompanion").setup({
      strategies = {
        chat = {
          adapter = adapters.extend("openai", {
            url = "http://localhost:8666/v1/chat/completions",
            env = {
              api_key = "sk-1234567890abcdef1234567890abcdef",
            },
            schema = {
              model = {
                default = "qwen2.5-coder-14b",
              },
            },
          }),
        },
        inline = {
          adapter = "chat",
        },
      },
      display = {
        chat = {
          show_settings = true,
        },
      },
    })

    -- MAPPINGS CORRIGÉS --

    -- En mode Normal : On ouvre/ferme (Toggle)
    vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "CodeCompanion Chat Toggle" })

    -- En mode Visuel : On envoie la sélection au chat
    -- On utilise "Chat" et pas "Chat Toggle" pour qu'il traite la sélection
    vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat<cr>", { desc = "CodeCompanion Chat (Selection)" })

    -- Optionnel : Ajouter la sélection à un chat déjà ouvert sans changer de focus
    vim.keymap.set("v", "<leader>ca", "<cmd>CodeCompanionChat Add<cr>", { desc = "CodeCompanion Add Selection" })
    
    -- Actions générales
    vim.keymap.set({ "n", "v" }, "<leader>cp", "<cmd>CodeCompanionActions<cr>", { desc = "CodeCompanion Actions" })
  end,
}
