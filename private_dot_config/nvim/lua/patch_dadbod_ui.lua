local M = {}


function M.patch_query_buffer()
  print("[vim-dadbod-ui] patch_query_buffer running")
  local file = vim.fn.stdpath("data")
    .. "/lazy/vim-dadbod-ui/autoload/db_ui/query.vim"

  assert(vim.uv.fs_stat(file), "[vim-dadbod-ui] query.vim not found at " .. file)

  local lines = vim.fn.readfile(file)
  local updated = {}
  local in_target_function = false
  local changed = false

  for _, line in ipairs(lines) do
    -- Detect start of the specific function
    if line:match("^function!%s+s:query%.setup_buffer%(") then
      in_target_function = true
    end

    -- Only patch inside the function body
    if in_target_function and line:match("let b:db = a:db.conn") then
      table.insert(updated, "  let b:db = a:db.url  \" patched by lazy.nvim")
      changed = true
    else
      table.insert(updated, line)
    end

    -- End of function
    if in_target_function and line:match("^endfunction") then
      in_target_function = false
    end
  end

  if changed then
    vim.fn.writefile(updated, file)
    print("[vim-dadbod-ui] Patched s:query.setup_buffer to use a:db.url")
  end
end

return M

