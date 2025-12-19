-- lua/dap-setup.lua
--
-- DAP Go setup STABLE et PROTÉGÉ :
-- - Telescope pour choisir cmd/*
-- - Input args simple (vim.fn.input)
-- - Breakpoints & ligne courante bien visibles
-- - État DAP (Running / Stopped) dans la statusline
-- - Protection contre les restarts en boucle
-- - Validation de session avant restart
-- - Debounce F5 pour éviter le menu d'initialisation
-- - Messages temporaires qui s'effacent après 2 secondes

local dap = require("dap")

---------------------------------------------------------------------
-- FONCTION MESSAGE TEMPORAIRE
---------------------------------------------------------------------

-- Affiche un message qui s'efface automatiquement après un délai
local function echo_temp(msg, duration)
  duration = duration or 2000 -- 2 secondes par défaut
  vim.cmd("echo '" .. msg:gsub("'", "''") .. "'")
  vim.defer_fn(function()
    vim.cmd("echon ''") -- Efface le message
  end, duration)
end

---------------------------------------------------------------------
-- BREAKPOINTS & LIGNE COURANTE : VISIBILITÉ FORTE
---------------------------------------------------------------------

vim.fn.sign_define("DapBreakpoint", {
  text = "●",
  texthl = "DapBreakpoint",
  linehl = "DapBreakpointLine",
  numhl = "",
})

vim.fn.sign_define("DapBreakpointCondition", {
  text = "◆",
  texthl = "DapBreakpointCondition",
  linehl = "DapBreakpointLine",
  numhl = "",
})

vim.fn.sign_define("DapStopped", {
  text = "▶",
  texthl = "DapStopped",
  linehl = "DapStoppedLine",
  numhl = "",
})

vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ff5555", bold = true })
vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ffaa00", bold = true })
vim.api.nvim_set_hl(0, "DapBreakpointLine", { bg = "#3a1f1f" })

vim.api.nvim_set_hl(0, "DapStopped", { fg = "#50fa7b", bold = true })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#1f3a2f" })

---------------------------------------------------------------------
-- ÉTAT DAP (RUNNING / STOPPED) DANS LA STATUSLINE
---------------------------------------------------------------------

_G.dap_status = function()
  if dap.session() then
    return " 🐞 " .. dap.status()
  end
  return ""
end

vim.api.nvim_create_autocmd("User", {
  pattern = "DAP*",
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

vim.o.statusline = vim.o.statusline .. "%{v:lua.dap_status()}"

---------------------------------------------------------------------
-- ÉTAT MÉMOIRE : DERNIÈRE COMMANDE GO
---------------------------------------------------------------------

local last_go = {
  program = nil,
  args = {},
}

---------------------------------------------------------------------
-- PROTECTION CIRCUIT BREAKER
---------------------------------------------------------------------

local restart_lock = false
local restart_count = 0
local max_restarts = 3
local last_restart_time = 0

local function reset_restart_counter()
  vim.defer_fn(function()
    if restart_count > 0 then
      restart_count = 0
    end
  end, 2000)
end

---------------------------------------------------------------------
-- WRAPPER RESTART PROTÉGÉ
---------------------------------------------------------------------

local original_restart = dap.restart

dap.restart = function(...)
  local now = vim.loop.now()
  
  -- Si moins de 500ms depuis le dernier restart
  if now - last_restart_time < 500 then
    restart_count = restart_count + 1
  else
    restart_count = 1
  end
  
  last_restart_time = now
  
  -- Circuit breaker
  if restart_count > max_restarts then
    echo_temp("🛑 TROP DE RESTARTS (" .. restart_count .. ") - Attendre 5s", 5000)
    vim.defer_fn(function()
      restart_count = 0
    end, 5000)
    return
  end
  
  -- Lock temporaire
  if restart_lock then
    echo_temp("⏳ Restart en cours...", 1000)
    return
  end
  
  -- Vérifier qu'une session existe et est initialisée
  local session = dap.session()
  if not session then
    echo_temp("⚠️  Pas de session active pour restart")
    return
  end
  
  -- Vérifier que la config est valide
  if not last_go.program then
    echo_temp("⚠️  Pas de programme configuré (utilise :GoDebugSet)")
    return
  end
  
  restart_lock = true
  echo_temp("♻️  Restart #" .. restart_count, 1500)
  
  vim.defer_fn(function()
    restart_lock = false
  end, 1000)
  
  reset_restart_counter()
  
  -- Appeler l'original seulement si tout est OK
  local ok, err = pcall(original_restart, ...)
  if not ok then
    echo_temp("❌ Erreur restart: " .. tostring(err), 3000)
    restart_lock = false
    restart_count = 0
  end
  
  return ok
end

---------------------------------------------------------------------
-- CONFIGURATION DAP GO (avec validation)
---------------------------------------------------------------------

dap.configurations.go = {
  {
    type = "go",
    name = "Debug Go (cmd)",
    request = "launch",
    program = function()
      if not last_go.program then
        echo_temp("⚠️  Program not set! Use :GoDebugSet")
        return vim.fn.getcwd() -- fallback sécurisé
      end
      return last_go.program
    end,
    args = function()
      return last_go.args or {}
    end,
  },
}

---------------------------------------------------------------------
-- TELESCOPE : CHOISIR cmd/*
---------------------------------------------------------------------

vim.api.nvim_create_user_command("GoDebugSet", function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Go commands (cmd/*)",
    finder = finders.new_oneshot_job({
      "find", "cmd", "-maxdepth", "2", "-type", "d",
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(bufnr)

        last_go.program = vim.fn.getcwd() .. "/" .. entry[1]

        local args = vim.fn.input(
          "Args: ",
          table.concat(last_go.args, " ")
        )

        last_go.args = args ~= "" and vim.split(args, " ") or {}
        dap.run(dap.configurations.go[1])
      end)
      return true
    end,
  }):find()
end, {})

---------------------------------------------------------------------
-- RELANCER SANS PROMPT
---------------------------------------------------------------------

vim.api.nvim_create_user_command("GoDebugRun", function()
  if not last_go.program then
    echo_temp("No Go debug configuration yet")
    return
  end
  dap.run(dap.configurations.go[1])
end, {})

---------------------------------------------------------------------
-- KEYMAPS INTELLIGENTS AVEC DEBOUNCE
---------------------------------------------------------------------

-- Variables de debounce pour F5
local last_f5_time = 0
local f5_cooldown = 300 -- ms

vim.keymap.set("n", "<leader>dr", "<Cmd>GoDebugSet<CR>",
  { desc = "DAP: pick Go command (Telescope)" })

-- F5 : Continue/Rerun avec protection initialisation + debounce
vim.keymap.set("n", "<F5>", function()
  local now = vim.loop.now()
  
  -- Debounce : ignore silencieusement si trop rapide
  if now - last_f5_time < f5_cooldown then
    return
  end
  
  last_f5_time = now
  
  if not last_go.program then
    echo_temp("📋 Pas encore configuré → lancement de GoDebugSet")
    vim.cmd("GoDebugSet")
    return
  end
  
  local session = dap.session()
  
  if session then
    -- Vérifier si vraiment initialisée
    if session.initialized then
      dap.continue()
    else
      -- Message temporaire 1 seconde
      echo_temp("⏳ Session en cours d'initialisation...", 1000)
    end
  else
    -- Pas de session : relancer
    dap.run_last()
  end
end, { desc = "DAP: continue or rerun" })

-- F6 : Restart (seulement si session active et initialisée)
vim.keymap.set("n", "<F6>", function()
  local session = dap.session()
  
  if not session then
    echo_temp("⚠️  Pas de session active, utilise F5 pour lancer")
    return
  end
  
  if not session.initialized then
    echo_temp("⚠️  Session non initialisée, attendre...")
    return
  end
  
  if not last_go.program then
    echo_temp("⚠️  Programme non configuré")
    return
  end
  
  dap.restart()
end, { desc = "DAP: restart (protected)" })

-- Navigation
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP: step out" })
vim.keymap.set("n", "<F8>", dap.terminate, { desc = "DAP: terminate" })



---------------------------------------------------------------------
-- DAP-UI
---------------------------------------------------------------------
local dapui = require("dapui")

---------------------------------------------------------------------
-- ÉTAT GLOBAL
---------------------------------------------------------------------
_G.dapui_is_open = false

---------------------------------------------------------------------
-- SETUP DAP-UI (CONFIG IDENTIQUE, FACTORISÉE)
---------------------------------------------------------------------
local function setup_dapui()
  dapui.setup({
    layouts = {
      -----------------------------------------------------------------
      -- PANNEAU GAUCHE (FULL HEIGHT)
      -----------------------------------------------------------------
      {
        elements = {
          { id = "repl",        size = 0.30 },
          { id = "console",     size = 0.20 },
          { id = "watches",     size = 0.25 },
          { id = "stacks",      size = 0.15 },
          { id = "breakpoints", size = 0.10 },
        },
        size = 40,
        position = "left",
      },

      -----------------------------------------------------------------
      -- PANNEAU BAS (SOUS LE CODE UNIQUEMENT)
      -----------------------------------------------------------------
      {
        elements = {
          "scopes",
        },
        size = 15,
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
    expand_lines = false
  })
end

-- setup initial
setup_dapui()

---------------------------------------------------------------------
-- RESIZE AUTO 30 % (INCHANGÉ)
---------------------------------------------------------------------
local function dapui_apply_min_size()
  if not _G.dapui_is_open then
    return
  end

  local min_left   = math.floor(vim.o.columns * 0.30)
  local min_bottom = math.floor(vim.o.lines   * 0.30)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft  = vim.bo[buf].filetype

    if ft == "dapui_repl"
      or ft == "dapui_console"
      or ft == "dapui_watches"
      or ft == "dapui_stacks"
      or ft == "dapui_breakpoints" then
      pcall(vim.api.nvim_win_set_width, win, min_left)
    end

    if ft == "dapui_scopes" then
      pcall(vim.api.nvim_win_set_height, win, min_bottom)
    end
  end
end

---------------------------------------------------------------------
-- OUVERTURE / FERMETURE AUTOMATIQUE
---------------------------------------------------------------------
dap.listeners.after.event_initialized["dapui"] = function()
  setup_dapui()                 -- 🔴 rappel explicite
  dapui.open({ reset = true })
  _G.dapui_is_open = true
  vim.defer_fn(dapui_apply_min_size, 20)
end

dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
  _G.dapui_is_open = false
end

dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
  _G.dapui_is_open = false
end

---------------------------------------------------------------------
-- TOGGLE MANUEL
---------------------------------------------------------------------
vim.keymap.set("n", "<leader>du", function()
  if _G.dapui_is_open then
    dapui.close()
    _G.dapui_is_open = false
  else
    setup_dapui()               -- 🔴 rappel explicite
    dapui.open({ reset = true })
    _G.dapui_is_open = true
    vim.defer_fn(dapui_apply_min_size, 20)
  end
end, { desc = "DAP UI: toggle" })



---------------------------------------------------------------------
-- DAP-UI : CONFIGURATION FINALE (TA VERSION)
---------------------------------------------------------------------
local dapui = require("dapui")

---------------------------------------------------------------------
-- ÉTAT GLOBAL
---------------------------------------------------------------------
_G.dapui_is_open = false

---------------------------------------------------------------------
-- TA CONFIG DAPUI (INCHANGÉE)
---------------------------------------------------------------------
local function dapui_setup()
  dapui.setup({
    layouts = {
      -----------------------------------------------------------------
      -- PANNEAU GAUCHE (FULL HEIGHT)
      -----------------------------------------------------------------
      {
        elements = {
          { id = "repl",        size = 0.30 },
          { id = "console",     size = 0.20 },
          { id = "watches",     size = 0.25 },
          { id = "stacks",      size = 0.15 },
          { id = "breakpoints", size = 0.10 },
        },
        size = 40,
        position = "left",
      },

      -----------------------------------------------------------------
      -- PANNEAU BAS (SCOPES)
      -----------------------------------------------------------------
      {
        elements = { "scopes" },
        size = 15,
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
end

-- setup initial
dapui_setup()

---------------------------------------------------------------------
-- RESIZE AUTO 30 % (TA VERSION)
---------------------------------------------------------------------
local function dapui_apply_min_size()
  if not _G.dapui_is_open then return end

  local min_left   = math.floor(vim.o.columns * 0.30)
  local min_bottom = math.floor(vim.o.lines   * 0.30)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft  = vim.bo[buf].filetype

    if ft == "dap-repl"
      or ft == "dapui_console"
      or ft == "dapui_watches"
      or ft == "dapui_stacks"
      or ft == "dapui_breakpoints" then
      pcall(vim.api.nvim_win_set_width, win, min_left)
    end

    if ft == "dapui_scopes" then
      pcall(vim.api.nvim_win_set_height, win, min_bottom)
    end
  end
end

---------------------------------------------------------------------
-- OUVERTURE / FERMETURE AUTOMATIQUE (SEULE MODIF : setup AVANT open)
---------------------------------------------------------------------
dap.listeners.after.event_initialized["dapui"] = function()
  dapui_setup()                      -- ✅ AJOUT
  dapui.open({ reset = true })
  _G.dapui_is_open = true
  vim.defer_fn(dapui_apply_min_size, 20)
end

dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
  _G.dapui_is_open = false
end

dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
  _G.dapui_is_open = false
end

---------------------------------------------------------------------
-- TOGGLE MANUEL (SEULE MODIF : setup AVANT open)
---------------------------------------------------------------------
vim.keymap.set("n", "<leader>du", function()
  if _G.dapui_is_open then
    dapui.close()
    _G.dapui_is_open = false
  else
    dapui_setup()                    -- ✅ AJOUT
    dapui.open({ reset = true })
    _G.dapui_is_open = true
    vim.defer_fn(dapui_apply_min_size, 20)
  end
end, { desc = "DAP UI: toggle" })


---------------------------------------------------------------------
-- LOGIQUE FINALE :q ET <leader>dq (UNIFIÉE)
---------------------------------------------------------------------

local function unified_quit(force_all)
  local dap = require("dap")
  local dapui = require("dapui")
  local dapui_fts = {
    "dap-repl", "dapui_console", "dapui_watches", 
    "dapui_stacks", "dapui_breakpoints", "dapui_scopes"
  }

  -- 1. CAS : APPEL VIA <leader>dq (ON FERME TOUT QUOI QU'IL ARRIVE)
  if force_all then
    dap.terminate()
    dapui.close()
    _G.dapui_is_open = false
    vim.cmd("qa")
    return
  end

  -- 2. CAS : APPEL VIA :q (INTERCEPTION)
  local ft = vim.bo.filetype
  local is_dap = false
  for _, d_ft in ipairs(dapui_fts) do
    if ft == d_ft then is_dap = true break end
  end

  if is_dap then
	  vim.api.nvim_echo({
		  {"🚫 Interdit : ", "ErrorMsg"},
		  {"<leader>du", "Identifier"}, {" pour masquer, ", "Normal"},
		  {"<leader>dq", "Identifier"}, {" pour tout quitter.", "Normal"}
	  }, false, {})
	  return
  end

  -- Compter les fenêtres de code normales
  local normal_wins = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local win_ft = vim.bo[buf].filetype
    local win_is_dap = false
    for _, d_ft in ipairs(dapui_fts) do
      if win_ft == d_ft then win_is_dap = true break end
    end
    if not win_is_dap then normal_wins = normal_wins + 1 end
  end

  -- Décider : Fermer juste la fenêtre ou tout Nvim
  if normal_wins <= 1 then
    dap.terminate()
    vim.cmd("qa")
  else
    vim.cmd("q")
  end
end

-- EXPOSITION GLOBALE
_G.SmartQuitAction = function() unified_quit(false) end
_G.ForceQuitAll = function() unified_quit(true) end

-- 1. Le mapping pour <leader>dq (Direct et Radical)
vim.keymap.set("n", "<leader>dq", "<cmd>lua ForceQuitAll()<CR>", { desc = "DAP: Stop and Quit Nvim" })

-- 2. L'interception du :q (Sécurité et Aide)
vim.keymap.set("c", "<CR>", function()
  if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q" then
    return "<C-u>lua SmartQuitAction()<CR>"
  end
  return "<CR>"
end, { expr = true })
