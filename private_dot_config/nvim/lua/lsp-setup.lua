vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf, silent = true }

        -- Navigation (remplace ctags)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

        -- Aide
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    end,
})

local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
    vim.lsp.protocol.make_client_capabilities =
        cmp_lsp.default_capabilities
end

