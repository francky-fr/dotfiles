require('smart-splits').setup({
			amount = 2,
			resize_mode = {
				resize_keys = { '<Left>', '<Down>', '<Up>', '<Right>' },
			},
})
vim.api.nvim_set_keymap('n', '<C-x>', [[<Cmd>lua require('smart-splits').start_resize_mode()<CR>]], { noremap = true, silent = true })

