return {
  {
    "jpalardy/vim-slime",
    init = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_default_config = {
        target_pane = "work:python.0",
        socket_name = "default",
      }
      vim.g.slime_dont_ask_default = 1
      vim.g.slime_no_mappings = true
      vim.g.slime_bracketed_paste = 1
    end,
    config = function()
      -- Envoie la sélection visuelle → IPython
      vim.keymap.set("v", "rr", "<Plug>SlimeRegionSend", { silent = true })
      -- Envoie tout le fichier → IPython
      vim.keymap.set("n", "rf", ":%SlimeSend<CR>", { silent = true })
      -- Désactive r seul
      vim.keymap.set("n", "r", "<nop>", { noremap = true })

      -- <C-s> et ss : contextuels selon le filetype
      -- (définis dans quarto.lua et sql.lua par autocommand)
    end,
  },
}
