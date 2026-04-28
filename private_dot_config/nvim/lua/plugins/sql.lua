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
            on_stderr = function(_, data)
              if data and data[1] ~= "" then
                vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
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

      local function reopen()
        vim.fn.jobstart(
          { "uv", "run", "python3", "-c",
            "import webbrowser; webbrowser.open('file:///tmp/duckdb_result.html')" },
          { detach = true }
        )
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql" },
        callback = function()
          -- <C-e> : envoie la sélection visuelle → DuckDB → navigateur
          vim.keymap.set("v", "<C-e>", send_selection, {
            buffer = true,
            desc   = "DuckDB: sélection → navigateur",
            silent = true,
          })
          -- ee : envoie la ligne courante → DuckDB → navigateur
          vim.keymap.set("n", "ee", send_current_line, {
            buffer = true,
            desc   = "DuckDB: ligne courante → navigateur",
            silent = true,
          })
          -- rouvre le dernier résultat
          vim.keymap.set("n", "<leader>do", reopen, {
            buffer = true,
            desc   = "DuckDB: rouvre le résultat",
            silent = true,
          })
        end,
      })

    end,
  },
}
