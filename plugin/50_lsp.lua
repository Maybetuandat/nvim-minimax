require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright" },
})

local function get_python_path()
  local cwd = vim.fn.getcwd()
  local local_venv = cwd .. "/.venv/bin/python"
  if vim.fn.executable(local_venv) == 1 then
    return local_venv
  end
  local venv_env = os.getenv("VIRTUAL_ENV")
  if venv_env then
    return venv_env .. "/bin/python"
  end
  return vim.fn.exepath("python3") or "python3"
end

vim.lsp.config('pyright', {
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path()
  end,
  settings = {
    python = {
      analysis = {
        autoImportCompletions = true,
        indexing = true,
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        diagnosticMode = "workspace",
      },
    },
  },
})

vim.lsp.enable('pyright')
