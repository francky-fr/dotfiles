return {
  {
    dir = vim.fn.stdpath("config"),
    name = "vim-web-out",
    lazy = false,
    config = function()
      local PORT = vim.g.duckdb_server_port or 8765
      local BASE = "http://127.0.0.1:" .. PORT

      -- Envoie les lignes [start_line, end_line] au serveur
      local function send_sql_lines(start_line, end_line)
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
        local query = table.concat(lines, "\n")

        -- 1. Vérifie que le serveur est up (timeout 1s)
        vim.fn.jobstart(
          { "curl", "-sf", "--max-time", "1", BASE .. "/ping" },
          {
            on_exit = function(_, ping_code)
              if ping_code ~= 0 then
                vim.schedule(function()
                  vim.notify(
                    "vim-web-out: serveur non disponible — lance-le avec :\n"
                      .. "  uv run python server.py --db ./mon_projet.db",
                    vim.log.levels.ERROR,
                    { title = "vim-web-out" }
                  )
                end)
                return
              end

              -- 2. Envoie la requête en POST (timeout 10s)
              -- --fail-with-body : exit 22 si HTTP 4xx/5xx, mais stdout contient
              -- quand même le body JSON → on peut en extraire le message d'erreur.
              local stdout_chunks = {}
              local job = vim.fn.jobstart(
                {
                  "curl", "-s", "--fail-with-body", "--max-time", "10",
                  "-X", "POST",
                  "-H", "Content-Type: text/plain",
                  "--data-binary", "@-",
                  BASE .. "/query",
                },
                {
                  stdin = "pipe",
                  on_stdout = function(_, data)
                    if data then
                      for _, l in ipairs(data) do
                        if l ~= "" then table.insert(stdout_chunks, l) end
                      end
                    end
                  end,
                  on_exit = function(_, code)
                    vim.schedule(function()
                      if code ~= 0 then
                        -- Tente d'extraire le champ "detail" du JSON FastAPI
                        local body = table.concat(stdout_chunks, "")
                        local detail
                        if body ~= "" then
                          local ok, parsed = pcall(vim.fn.json_decode, body)
                          if ok and type(parsed) == "table" and parsed.detail then
                            detail = tostring(parsed.detail)
                          else
                            detail = body
                          end
                        end
                        vim.notify(
                          "vim-web-out: " .. (detail or ("erreur inconnue (curl " .. code .. ")")),
                          vim.log.levels.ERROR,
                          { title = "vim-web-out" }
                        )
                      else
                        vim.notify(
                          BASE .. "/",
                          vim.log.levels.INFO,
                          { title = "vim-web-out" }
                        )
                      end
                    end)
                  end,
                }
              )
              vim.fn.chansend(job, query)
              vim.fn.chanclose(job, "stdin")
            end,
          }
        )
      end

      local function send_selection()
        send_sql_lines(vim.fn.line("'<"), vim.fn.line("'>"))
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false
        )
      end

      local function send_current_line()
        local line = vim.fn.line(".")
        send_sql_lines(line, line)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql" },
        callback = function()
          vim.keymap.set("v", "<C-e>", send_selection, {
            buffer = true,
            desc   = "DuckDB: sélection → navigateur",
            silent = true,
          })
          vim.keymap.set("n", "ee", send_current_line, {
            buffer = true,
            desc   = "DuckDB: ligne courante → navigateur",
            silent = true,
          })
        end,
      })
    end,
  },
}
