return {
  {
    dir = vim.fn.stdpath("config"),
    name = "duckdb-send",
    lazy = false,
    config = function()

      local function get_db_path()
        local db = vim.fn.glob(vim.fn.getcwd() .. "/*.db")
        return db ~= "" and db or ":memory:"
      end

      local function send_sql_lines(start_line, end_line)
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
        local query = table.concat(lines, "\n")
        local script = vim.fn.expand("~/.config/nvim/scripts/duckdb_send.py")

        local job = vim.fn.jobstart(
          { "uv", "run", "python3", script, get_db_path() },
          {
            stdin = "pipe",
            on_stdout = function(_, data)
              if not data then return end
              for _, line in ipairs(data) do
                if line:match("^REMOTE:") then
                  local url = line:gsub("^REMOTE:", "")
                  if not vim.g.duckdb_server_notified then
                    vim.g.duckdb_server_notified = true
                    vim.schedule(function()
                      vim.notify(
                        "DuckDB — ouvre dans ton navigateur :\n" .. url,
                        vim.log.levels.INFO,
                        { title = "DuckDB" }
                      )
                    end)
                  end
                end
              end
            end,
            on_stderr = function(_, data)
              if data then
                local msg = table.concat(data, "\n"):gsub("^%s*(.-)%s*$", "%1")
                if msg ~= "" then
                  vim.schedule(function()
                    vim.notify("DuckDB: " .. msg, vim.log.levels.ERROR)
                  end)
                end
              end
            end,
          }
        )
        vim.fn.chansend(job, query)
        vim.fn.chanclose(job, "stdin")
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
