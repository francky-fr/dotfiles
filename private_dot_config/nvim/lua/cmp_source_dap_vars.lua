local source = {}

function source:is_available()
  return require("dap").session() ~= nil
end

function source:get_trigger_characters()
  return { "." }
end

function source:complete(params, callback)
  local dap = require("dap")
  local session = dap.session()
  
  if not session or not session.current_frame then
    callback({ items = {}, isIncomplete = false })
    return
  end
  
  -- Récupérer toutes les variables du scope actuel
  local items = {}
  
  session:request("scopes", { frameId = session.current_frame.id }, function(err, resp)
    if err or not resp or not resp.scopes then
      callback({ items = {}, isIncomplete = false })
      return
    end
    
    local completed_scopes = 0
    local total_scopes = #resp.scopes
    
    if total_scopes == 0 then
      callback({ items = {}, isIncomplete = false })
      return
    end
    
    for _, scope in ipairs(resp.scopes) do
      session:request("variables", { variablesReference = scope.variablesReference }, function(err2, vars_resp)
        if not err2 and vars_resp and vars_resp.variables then
          for _, var in ipairs(vars_resp.variables) do
            table.insert(items, {
              label = var.name,
              kind = require("cmp").lsp.CompletionItemKind.Variable,
              detail = var.type or "runtime var",
              documentation = {
                kind = "markdown",
                value = string.format("**Value:** `%s`\n**Type:** `%s`", var.value or "?", var.type or "?"),
              },
            })
          end
        end
        
        completed_scopes = completed_scopes + 1
        
        -- Callback une seule fois quand tout est récupéré
        if completed_scopes == total_scopes then
          callback({ items = items, isIncomplete = false })
        end
      end)
    end
  end)
end

return source
