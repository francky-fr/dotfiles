-- Shortcuts to change windows

_G.conditional_window_move = function(direction, fallback_key)
  local current_window = vim.fn.winnr()  -- Get the current window number
  local status, err = pcall(function()
    vim.cmd("silent! wincmd " .. direction)
  end)
  if not status then
    print("Error during wincmd:", err)
    return
  end
  local new_window = vim.fn.winnr()  -- Get the new window number after the move
  if new_window == current_window then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(fallback_key, true, false, true), 'n', false)
  end
end

vim.keymap.set(
  'n', 
  '<C-Right>', 
  function() _G.conditional_window_move("l", "<C-Right>") end, 
  { noremap = true, silent = true }
)

vim.keymap.set(
  'n', 
  '<C-Left>', 
  function() _G.conditional_window_move("h", "<C-Left>") end, 
  { noremap = true, silent = true }
)

vim.keymap.set(
  'n', 
  '<C-Up>', 
  function() _G.conditional_window_move("k", "<C-Up>") end, 
  { noremap = true, silent = true }
)

vim.keymap.set(
  'n', 
  '<C-Down>', 
  function() _G.conditional_window_move("j", "<C-Down>") end, 
  { noremap = true, silent = true }
)
