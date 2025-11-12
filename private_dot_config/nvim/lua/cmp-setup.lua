local cmp = require'cmp'

-- Common settings
local common_settings = {
    preselect = cmp.PreselectMode.None,
    completion = {
        completeopt = 'menu,menuone,noinsert,noselect',
        -- Remove 'autocomplete' setting from common settings
    },
}

-- Common mappings
local common_mappings = {
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping(function(fallback)
        if cmp.visible() and cmp.get_selected_entry() then
            cmp.confirm({ select = false })
        else
            fallback()
        end
    end, { 'i', 's', 'c' }),
}

-- Insert mode mappings
local insert_mode_mappings = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
            fallback()
        end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
        else
            fallback()
        end
    end, { 'i', 's' }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<Del>'] = cmp.mapping.abort(),
})

-- Merge common mappings into insert mode mappings
for k, v in pairs(common_mappings) do
    insert_mode_mappings[k] = v
end

-- Command-line mode mappings
local cmdline_mode_mappings = {
    ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
            cmp.complete()
        end
    end, { 'c' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
        else
            cmp.complete()
        end
    end, { 'c' }),
    -- Up and Down mappings
    ['<Up>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
        else
            fallback()  -- Navigate command history
        end
    end, { 'c' }),
    ['<Down>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
            fallback()  -- Navigate command history
        end
    end, { 'c' }),
    -- Mapping for <Esc>
    ['<Esc>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.close()
        else
            -- Do nothing; prevent default behavior of <Esc> erasing the command line
        end
    end, { 'c' }),
    -- Optionally, map <C-c> to cancel the command line
    ['<C-c>'] = cmp.mapping(function(fallback)
        -- Cancel the command line
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, true, true), 'n', true)
    end, { 'c' }),
}

-- Merge common mappings into command-line mode mappings
for k, v in pairs(common_mappings) do
    cmdline_mode_mappings[k] = v
end

-- Setup for insert mode
cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    mapping = insert_mode_mappings,
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
        { name = 'path' },
        { name = "vim-dadbod-completion" },
	{ name = "fish"},
    }, {
        { name = 'buffer' },
    }),
    preselect = common_settings.preselect,
    completion = common_settings.completion,
})

-- Setup for command-line mode
cmp.setup.cmdline(':', {
    mapping = cmdline_mode_mappings,
    sources = cmp.config.sources({
        { name = 'path' },
    }, {
        { name = 'cmdline' },
    }),
    preselect = cmp.PreselectMode.None,
    completion = {
        autocomplete = false,  -- Disable automatic completion
        completeopt = 'menu,menuone,noinsert,noselect',
    },
})

-- Optional: Setup for search mode
cmp.setup.cmdline('/', {
    mapping = cmdline_mode_mappings,
    sources = {
        { name = 'buffer' }
    },
    preselect = cmp.PreselectMode.None,
    completion = {
        autocomplete = false,  -- Disable automatic completion
        completeopt = 'menu,menuone,noinsert,noselect',
    },
})
