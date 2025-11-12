vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_save_location = "~/queries/"

-- Function to map <C-s> to save the query
function _G.map_ctrl_s_for_save_query()
  if vim.bo.filetype == "sql" then
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-s>', '<Plug>(DBUI_SaveQuery)', { noremap = true, silent = true })
  end
end

vim.api.nvim_exec([[
  augroup DBUIMapCtrlS
    autocmd!
    autocmd FileType sql lua map_ctrl_s_for_save_query()
  augroup END
]], false)


vim.keymap.set("n", "<C-y>", '<Plug>(DBUI_Redraw)' , { noremap = true, silent = true })
vim.keymap.set("n", "<C-r>", db_refresh_all, { noremap = true, silent = true })


-- For query Execution
vim.keymap.set('n', '<C-e>', ":%DB<CR>", { noremap = true, silent = true })
vim.keymap.set('x', '<C-e>', 'db#op_exec()', { expr = true })
vim.keymap.set('n', 'ee', ":.DB<CR>", { noremap = true, silent = true })

-- Refresh
vim.api.nvim_set_keymap('n', '<C-d>', '<Plug>(DBUI_Redraw)', { noremap = true, silent = true })

-- Redshift Compat
vim.g.db_ui_use_postgres_views = 0
