require('mason').setup()
require('mason-lspconfig').setup({
    ensure_installed = { "pyright", "sqls" } -- Automatically install Pyright
})
-- require('lspconfig').pyright.setup{}

