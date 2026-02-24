require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright" }, 
})

vim.lsp.enable('pyright') 

-- Nếu muốn thêm config chi tiết cho pyright:
-- vim.lsp.config('pyright', {
--   cmd = { "pyright-langserver", "--stdio" },
--   filetypes = { "python" },
--   -- các cài đặt khác...
-- })

-- Nếu sau này bạn code Java (jdtls):
-- vim.lsp.enable('jdtls')
