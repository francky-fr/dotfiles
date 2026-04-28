dap = require("dap")
---------------------------------------------------------------------
-- ADAPTER DELVE (MANQUANT !)
---------------------------------------------------------------------
dap.adapters.go = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" , "--log"},
  },
}

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
  
  -- Vérifier qu'une smeession existe et est initialisée
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
	  buildFlags = "-gcflags='all=-N -l'",
	  outputMode = "remote",
	  console = 'integratedTerminal'
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
local function dap_start_or_continue()
  local now = vim.loop.now()

  -- Debounce
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
    if session.initialized then
      dap.continue()
    else
      echo_temp("⏳ Session en cours d'initialisation...", 1000)
    end
  else
    dap.run_last()
  end
end

vim.keymap.set("n", "<F5>", function()
  dap_start_or_continue()
end, { desc = "DAP: continue or start" })

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
  
  dap.terminate()
  vim.wait(200, function()
	  return dap.session() == nil
  end)
  dap_start_or_continue()
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

_G.dapui_is_open = false
local dapui = require("dapui")

---------------------------------------------------------------------
-- OUVERTURE / FERMETURE AUTOMATIQUE
---------------------------------------------------------------------
dap.listeners.after.event_initialized["dapui"] = function()
	vim.notify("dap.listeners.after.event_initialized")

	dapui.open({ reset = true })
	_G.dapui_is_open = true
	-- vim.defer_fn(dapui_apply_min_size, 20)
end

dap.listeners.before.event_terminated["dapui"] = function()
	vim.notify("dap.listeners.after.event_terminated")
	dapui.close()
	_G.dapui_is_open = false
end

dap.listeners.before.event_exited["dapui"] = function()
	vim.notify("dap.listeners.after.event_exited")
	dapui.close()
	_G.dapui_is_open = false
end

---------------------------------------------------------------------
-- TOGGLE MANUEL
---------------------------------------------------------------------
vim.keymap.set("n", "<leader>du", function()
	if _G.dapui_is_open then
		vim.notify("<leader>du (starting state dpui is open)")
		dapui.close()
		_G.dapui_is_open = false
	else
		vim.notify("<leader>du (starting state dpui is not open)")
		-- setup_dapui()
		dapui.open({ reset = true })
		_G.dapui_is_open = true
		-- vim.defer_fn(dapui_apply_min_size, 20)
	end
end, { desc = "DAP UI: toggle" })


---------------------------------------------------------------------
-- RESIZE AUTO 30 % (TA VERSION)
---------------------------------------------------------------------
local function dapui_apply_min_size()
		vim.notify("apply_min_size")
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

vim.api.nvim_create_autocmd("VimResized", {
  callback = dapui_apply_min_size,
})


---------------------------------------------------------------------
-- LOGIQUE FINALE :q ET <leader>dq (UNIFIÉE)
---------------------------------------------------------------------

local function unified_quit(force_all)
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

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "dapui_console" },
--   callback = function()
--     vim.opt_local.wrap = true
--     vim.opt_local.linebreak = true
--     vim.opt_local.breakindent = true
--     vim.opt_local.showbreak = "↪ "
--   end,
-- })

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "dapui_console" },
--   callback = function()
--     vim.opt_local.wrap = true
--     vim.opt_local.linebreak = true
--     vim.opt_local.scrolloff = 0
--     vim.opt_local.sidescrolloff = 0
--     vim.opt_local.sidescroll = 0
--   end,
-- })
-- vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
--   callback = function()
--     local win = vim.api.nvim_get_current_win()
--     local buf = vim.api.nvim_win_get_buf(win)
--
--     if vim.bo[buf].filetype == "dapui_console" then
--       vim.api.nvim_win_set_option(win, "wrap", true)
--       vim.api.nvim_win_set_option(win, "linebreak", true)
--       vim.api.nvim_win_set_option(win, "breakindent", true)
--       vim.api.nvim_win_set_option(win, "showbreak", "↪ ")
--     end
--   end,
-- })

local function apply_repl_wrap()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "dap-repl" then
      vim.api.nvim_win_set_option(win, "wrap", true)
      vim.api.nvim_win_set_option(win, "linebreak", true)

      -- IMPORTANT : pas de symbole de retour
      vim.api.nvim_win_set_option(win, "showbreak", "")

      -- optionnel : indentation propre
      vim.api.nvim_win_set_option(win, "breakindent", true)
    end
  end
end

dap.listeners.after.event_initialized["dapui_repl_wrap"] = function()
  vim.defer_fn(apply_repl_wrap, 50)
  vim.defer_fn(apply_repl_wrap, 200)
end

vim.api.nvim_create_autocmd({ "WinEnter", "VimResized" }, {
  callback = apply_repl_wrap,
})


-- dap.listeners.after.event_output["dapui_console"] = function(_, body)
--   if not body or not body.output then
--     return
--   end
--
--   -- catégories typiques : stdout | stderr | console
--   local category = body.category or "console"
--
--   -- écrire explicitement dans la console dap-ui
--   dapui.eval(body.output, { context = category })
-- end



-- local function enable_dap_completion(bufnr)
--   local cmp = require("cmp")
--   
--   -- Vérifier qu'une session DAP existe
--   if not require("dap").session() then
--     vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
--     return false
--   end
--
--   -- Configuration CMP pour ce buffer
--   -- cmp.setup.buffer({
--   --   sources = cmp.config.sources({
--   --     { name = 'nvim_lsp', priority = 1000 },   -- gopls
--   --     { name = 'buffer',   priority = 500 },
--   --   }),
--   --   completion = {
--   --     autocomplete = { 
--   --       cmp.TriggerEvent.TextChanged,
--   --       cmp.TriggerEvent.InsertEnter 
--   --     },
--   --   },
--   -- })
--     cmp.setup.buffer({
--     sources = cmp.config.sources({
--       { name = "nvim_lsp" },
--     }, {
--       { name = "buffer" },
--     }),
--     completion = {
--       autocomplete = {
--         cmp.TriggerEvent.TextChanged,
--         cmp.TriggerEvent.InsertEnter,
--       },
--     },
--   })
--
--   return true
-- end

-- vim.keymap.set("n", "<leader>dd", function()
--   -- 1. Créer le buffer
--   vim.cmd("vnew")
--   local bufnr = vim.api.nvim_get_current_buf()
--   vim.api.nvim_buf_set_name(bufnr, vim.fn.getcwd() .. "/dap-input.go")
--   
--   -- 2. Configuration buffer
--   vim.bo[bufnr].buftype = ""
--   vim.bo[bufnr].swapfile = false
--   vim.bo[bufnr].bufhidden = "wipe"
--   vim.bo[bufnr].filetype = "go"
--   
--   -- 3. ⚠️ ATTENDRE que gopls s'attache
--   vim.defer_fn(function()
--     -- Vérifier l'attachement LSP
--     local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })
--     
--     if #clients == 0 then
--       vim.notify("⚠️  gopls non attaché, retry...", vim.log.levels.WARN)
--       -- Retry une fois après 200ms supplémentaires
--       vim.defer_fn(function()
--         clients = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })
--         if #clients == 0 then
--           vim.notify("❌ gopls failed to attach", vim.log.levels.ERROR)
--           return
--         end
--         enable_dap_completion(bufnr)
--         vim.cmd("startinsert")
--       end, 200)
--       return
--     end
--     
--     -- gopls est attaché, configurer CMP
--     if enable_dap_completion(bufnr) then
--       vim.notify("✅ Debug input ready", vim.log.levels.INFO)
--     end
--     
--     vim.cmd("startinsert")
--   end, 300)  -- Délai initial pour l'attachement LSP
--   
-- end, { desc = "DAP: debug input buffer" })
--


-- ===================================================================
-- PARTIE 1 : Enregistrer la source CMP custom pour variables runtime
-- ===================================================================

-- Enregistrer la source dap_vars (Solution D)
local cmp = require("cmp")
cmp.register_source("dap_vars", require("cmp_source_dap_vars"))

-- ===================================================================
-- PARTIE 2 : Mapping <leader>dd avec template complet (Solution A + D)
-- ===================================================================

vim.keymap.set("n", "<leader>dd", function()
  -- 1. Créer le buffer
  vim.cmd("vnew")
  -- local bufnr = vim.api.nvim_get_current_buf()
  
  -- 2. Nom dans le projet (pas de préfixe ".")
  -- local temp_name = vim.fn.getcwd() .. "/debug-input-" .. os.time() .. ".go"
  -- FL POUR FAIRE MARCHE 2312
  -- local temp_name = vim.fn.getcwd() .. "/cmd/debug-input-1766500412.go"
  -- vim.api.nvim_buf_set_name(bufnr, temp_name)
  local path = vim.fn.getcwd() .. "/cmd/debug-input-1766500412.go"
  vim.cmd.edit(vim.fn.fnameescape(path))
  local bufnr = vim.api.nvim_get_current_buf()
  
  
  -- 3. Configuration buffer
  vim.bo[bufnr].buftype = ""
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].filetype = "go"
  
  -- 4. ⭐ Template auto-valide avec imports communs (Solution A)
  local lines = {
    "package main",
    "",
    "import (",
    '\t"fmt"',
    '\t"strings"',
    '\t"strconv"',
    '\t"time"',
    '\t"encoding/json"',
    '\t"context"',
    ")",
    "",
    "func debugEval() {",
    "\t// ⬇️ Évalue tes expressions ici",
    "\t// Variables runtime disponibles en autocomplétion",
    "\t",
    "}",
  }
  
  -- vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  -- 
  -- -- 5. Curseur sur la ligne vide (ligne 14)
  -- vim.api.nvim_win_set_cursor(0, {14, 1})
  
  -- 6. Attendre l'attachement gopls + configurer CMP
  vim.defer_fn(function()
    -- Vérifier gopls
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })
    
    if #clients == 0 then
      vim.notify("⚠️ gopls pas encore attaché, attente...", vim.log.levels.WARN)
      
      -- Retry
      vim.defer_fn(function()
        clients = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })
        
        if #clients == 0 then
          vim.notify("❌ gopls n'a pas pu s'attacher", vim.log.levels.ERROR)
          return
        end
        
        -- Configuration CMP après retry
        setup_dap_completion(bufnr)
        vim.cmd("startinsert")
      end, 300)
      
      return
    end
    
    -- gopls attaché, configurer CMP
    setup_dap_completion(bufnr)
    vim.notify("✅ Debug input ready (runtime vars + LSP)", vim.log.levels.INFO)
    vim.cmd("startinsert")
    
  end, 200)
  
end, { desc = "DAP: debug input (runtime + LSP)" })

-- ===================================================================
-- PARTIE 3 : Configuration CMP avec priorités (Solution D)
-- ===================================================================

function setup_dap_completion(bufnr)
  local cmp = require("cmp")
  
  -- Vérifier session DAP
  local has_dap_session = require("dap").session() ~= nil
  
  local sources
  if has_dap_session then
    -- ⭐ Avec session DAP : variables runtime en priorité
    sources = cmp.config.sources({
      { name = "dap_vars", priority = 2000 },  -- Variables runtime
      { name = "nvim_lsp", priority = 1000 },  -- Types Go (gopls)
      { name = "buffer",   priority = 500 },   -- Mots du buffer
    })
  else
    -- Sans session DAP : juste LSP
    sources = cmp.config.sources({
      { name = "nvim_lsp", priority = 1000 },
      { name = "buffer",   priority = 500 },
    })
  end
  
  cmp.setup.buffer({
    sources = sources,
    completion = {
      autocomplete = { 
        cmp.TriggerEvent.TextChanged,
        cmp.TriggerEvent.InsertEnter,
      },
    },
  })
end

-- ===================================================================
-- PARTIE 4 : Quick import (Solution B - bonus)
-- ===================================================================

-- Ajouter ce mapping dans le buffer debug pour importer rapidement
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "*/debug-input-*.go",
--   callback = function()
--     local bufnr = vim.api.nvim_get_current_buf()
--     
--     -- Mapping pour import rapide (insert mode uniquement)
--     vim.keymap.set("i", "<C-i>", function()
--       local pkg = vim.fn.input("Import package: ")
--       if pkg ~= "" then
--         local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--         
--         -- Trouver la ligne "import ("
--         for i, line in ipairs(lines) do
--           if line:match("^import %(") then
--             -- Ajouter l'import
--             vim.api.nvim_buf_set_lines(bufnr, i, i, false, {'\t"' .. pkg .. '"'})
--             vim.notify("✅ Importé: " .. pkg, vim.log.levels.INFO)
--             break
--           end
--         end
--       end
--     end, { buffer = bufnr, desc = "Quick import package" })
--     
--   end,
-- })

-- ===================================================================
-- ENVOI AU REPL DAP
-- ===================================================================

-- Envoyer la ligne courante au REPL
vim.keymap.set("n", "<leader>dl", function()
  local line = vim.api.nvim_get_current_line()
  
  -- Nettoyer la ligne (retirer commentaires, espaces)
  line = line:gsub("^%s*//.*", "")  -- Enlever commentaires //
  line = vim.trim(line)
  
  if line == "" then
    vim.notify("⚠️  Ligne vide", vim.log.levels.WARN)
    return
  end
  
  -- Vérifier session DAP
  if not require("dap").session() then
    vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
    return
  end
  
  -- Envoyer au REPL
  require("dap").repl.execute(line)
  vim.notify("📤 Envoyé: " .. line, vim.log.levels.INFO)
  
  -- Optionnel : ouvrir le REPL si pas visible
  if not _G.dapui_is_open then
    require("dapui").float_element("repl", { 
      width = 80, 
      height = 20,
      enter = false 
    })
  end
  
end, { desc = "DAP: send line to REPL" })

-- Envoyer la sélection visuelle au REPL
vim.keymap.set("v", "<leader>dl", function()
  -- Récupérer la sélection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  -- Concaténer les lignes
  local text = table.concat(lines, "\n")
  text = vim.trim(text)
  
  if text == "" then
    vim.notify("⚠️  Sélection vide", vim.log.levels.WARN)
    return
  end
  
  -- Vérifier session DAP
  if not require("dap").session() then
    vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
    return
  end
  
  -- Envoyer au REPL
  require("dap").repl.execute(text)
  vim.notify("📤 Envoyé: " .. #lines .. " ligne(s)", vim.log.levels.INFO)
  
  -- Optionnel : ouvrir le REPL
  if not _G.dapui_is_open then
    require("dapui").float_element("repl", { 
      width = 80, 
      height = 20,
      enter = false 
    })
  end
  
end, { desc = "DAP: send selection to REPL" })

-- ===================================================================
-- WATCH VARIABLES/EXPRESSIONS
-- ===================================================================

-- Watch le mot sous le curseur
vim.keymap.set("n", "<leader>dw", function()
  local word = vim.fn.expand("<cword>")
  
  if word == "" then
    vim.notify("⚠️  Pas de mot sous le curseur", vim.log.levels.WARN)
    return
  end
  
  -- Vérifier session DAP
  if not require("dap").session() then
    vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
    return
  end
  
  -- Ajouter au watch
  require("dapui").elements.watches.add(word)
  vim.notify("👁️  Watch ajouté: " .. word, vim.log.levels.INFO)
  
  -- Optionnel : ouvrir le panel watches si pas visible
  if not _G.dapui_is_open then
    require("dapui").open()
  end
  
end, { desc = "DAP: watch word under cursor" })

-- Watch une expression custom
vim.keymap.set("n", "<leader>dW", function()
  local expr = vim.fn.input("Watch expression: ")
  
  if expr == "" then
    return
  end
  
  -- Vérifier session DAP
  if not require("dap").session() then
    vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
    return
  end
  
  -- Ajouter au watch
  require("dapui").elements.watches.add(expr)
  vim.notify("👁️  Watch ajouté: " .. expr, vim.log.levels.INFO)
  
  -- Optionnel : ouvrir le panel watches
  if not _G.dapui_is_open then
    require("dapui").open()
  end
  
end, { desc = "DAP: watch custom expression" })

-- Watch la sélection visuelle
vim.keymap.set("v", "<leader>dw", function()
  -- Récupérer la sélection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local start_col = start_pos[3]
  local end_col = end_pos[3]
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  -- Si une seule ligne
  if #lines == 1 then
    lines[1] = lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
  end
  
  local expr = table.concat(lines, " ")
  expr = vim.trim(expr)
  
  if expr == "" then
    vim.notify("⚠️  Sélection vide", vim.log.levels.WARN)
    return
  end
  
  -- Vérifier session DAP
  if not require("dap").session() then
    vim.notify("⚠️  Pas de session DAP active", vim.log.levels.WARN)
    return
  end
  
  -- Ajouter au watch
  require("dapui").elements.watches.add(expr)
  vim.notify("👁️  Watch ajouté: " .. expr, vim.log.levels.INFO)
  
  -- Optionnel : ouvrir le panel watches
  if not _G.dapui_is_open then
    require("dapui").open()
  end
  
end, { desc = "DAP: watch selection" })

-- Nettoyer tous les watches
vim.keymap.set("n", "<leader>dC", function()
  require("dapui").elements.watches.clear()
  vim.notify("🗑️  Watches cleared", vim.log.levels.INFO)
end, { desc = "DAP: clear all watches" })
