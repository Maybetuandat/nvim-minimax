-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).

-- Tree-sitter ================================================================
now_if_args(function()
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
  })
  add({
    source = 'nvim-treesitter/nvim-treesitter-textobjects',
    checkout = 'main',
  })

  -- 1. Tạo thư mục cố định để lưu parser trong data của minimax
  local parser_install_dir = vim.fn.stdpath('data') .. '/parsers'
  vim.fn.mkdir(parser_install_dir, 'p')

  -- 2. QUAN TRỌNG: Thêm đường dẫn này vào đầu runtimepath ngay lập tức
  -- Nếu không có dòng này, Neovim sẽ không thấy parser đã cài và sẽ tải lại mãi mãi.
  vim.opt.runtimepath:prepend(parser_install_dir)

  -- 3. Cấu hình an toàn sử dụng pcall (tránh lỗi module not found)
  local configure_ts = function()
    local ok, configs = pcall(require, 'nvim-treesitter.configs')
    if not ok then return end

    configs.setup({
      -- Ép Treesitter luôn cài vào thư mục chúng ta đã định nghĩa
      parser_install_dir = parser_install_dir,
      
      ensure_installed = {
        'lua', 'vimdoc', 'markdown', 'javascript', 'typescript', 'tsx', 'html', 'css'
      },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end

  -- Chạy cấu hình sau khi Neovim đã ổn định
  vim.schedule(configure_ts)

  -- 4. Logic kích hoạt highlight theo filetype (giữ nguyên của bạn nhưng thêm bảo vệ)
  local languages = { 'lua', 'vimdoc', 'markdown', 'javascript', 'typescript', 'tsx', 'html', 'css' }
  local filetypes = {}
  for _, lang in ipairs(languages) do
    local ok, ft_list = pcall(vim.treesitter.language.get_filetypes, lang)
    if ok then
      for _, ft in ipairs(ft_list) do table.insert(filetypes, ft) end
    end
  end
  
  local ts_start = function(ev) pcall(vim.treesitter.start, ev.buf) end
  _G.Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)


-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin
-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add('stevearc/conform.nvim')

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require('conform').setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = 'fallback',
    },
     formatters_by_ft = {
      javascript      = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript      = { 'prettier' },
      typescriptreact = { 'prettier' },
      vue             = { 'prettier' },
      html            = { 'prettier' },
      css             = { 'prettier' },
      scss            = { 'prettier' },
      json            = { 'prettier' },
      markdown        = { 'prettier' },
      python          = { 'isort', 'black' },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = 'fallback',
    },
    -- Map of filetype to formatters
    -- Make sure that necessary CLI tool is available
    -- formatters_by_ft = { lua = { 'stylua' } },
  })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add('rafamadriz/friendly-snippets') end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
-- now_if_args(function()
--   add('mason-org/mason.nvim')
--   require('mason').setup()
-- end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
-- MiniDeps.now(function()
--   -- Install only those that you need
--   add('sainnhe/everforest')
--   add('Shatur/neovim-ayu')
--   add('ellisonleao/gruvbox.nvim')
--
--   -- Enable only one
--   vim.cmd('color everforest')
-- end)
-- )


-- ========================================================================== --
--                                SNACKS.NVIM                                 --
-- ========================================================================== --

local add = MiniDeps.add

-- 1. Chỉ khai báo tải plugin MỘT LẦN duy nhất
add({ source = 'folke/snacks.nvim' })

-- Tính toán thời gian trước
local function get_datetime()
  local days = {"Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"}
  local day_name = days[tonumber(os.date("%w")) + 1]
  return "📅 " .. day_name .. ", " .. os.date("%d/%m/%Y") .. "  •  🕐 " .. os.date("%H:%M")
end

local function get_footer()
  return "⚡ Neovim loaded with MiniMax  •  v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
end

require('snacks').setup({
  dashboard = {
    enabled = true,
    preset = {
      header = [[
   ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
   ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
   ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
   ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
   ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
      keys = {},
    },
    sections = {
      { section = "header", padding = 2 },
      
      -- Thời gian hiện tại
      { text = get_datetime(), align = "center", padding = 2 },

     -- Menu items với Nerd Font icons
      { icon = "\u{f002} ", title = "Find File",    action = ":lua Snacks.dashboard.pick('files')",    key = "f", padding = 1 },
      { icon = "\u{f15c} ", title = "Find Text",    action = ":lua Snacks.dashboard.pick('live_grep')", key = "g", padding = 1 },
      { icon = "\u{f15b} ", title = "New File",     action = ":ene | startinsert",                      key = "n", padding = 1 },
      { icon = "\u{f017} ", title = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')",  key = "r", padding = 1 },
      { icon = "\u{f487} ", title = "Plugins",      action = ":DepsShow",                               key = "p", padding = 1 },
      { icon = "\u{f013} ", title = "Config",       action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})", key = "c", padding = 1 },
      { icon = "\u{f011} ", title = "Quit",         action = ":qa",                                     key = "q", padding = 2 },
     -- Footer
      { text = get_footer(), align = "center", hl = "Comment" },
    },
  },
})
local add = MiniDeps.add

add({
  source = 'nvim-tree/nvim-tree.lua',
  depends = { 'nvim-tree/nvim-web-devicons' },
})

require("nvim-tree").setup({
  view = {
    width = 30,
    side = "left",
  },
  renderer = {
    group_empty = true, -- Rất hữu ích cho Java/Spring Boot
  },
  filters = {
    dotfiles = false, -- Hiển thị cả các file ẩn như .env
  },
})

-- config for language servers
local add = MiniDeps.add

-- Trình quản lý LSP, Linters, Formatters
add({ source = 'williamboman/mason.nvim' })

add('WhoIsSethDaniel/mason-tool-installer.nvim')
require('mason-tool-installer').setup({
  ensure_installed = {
    'prettier',
    'black',
    'isort',
  },
})


add({ source = 'williamboman/mason-lspconfig.nvim' })




-- Cấu hình LSP mặc định của Neovim
add({ 
  source = 'neovim/nvim-lspconfig',
  depends = { 'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim' }
})


-- plugins for enable markdown editor same with vscode editor
add({
  source = 'toppair/peek.nvim',
  -- This builds the app after installation
  hooks = { post_checkout = function() vim.fn.system('deno task --quiet build:fast') end },
})

-- Configure it to look like VS Code
require('peek').setup({
  auto_load = true,         -- smart load
  close_on_bdelete = true,  -- close preview when you close the buffer
  syntax = true,            -- enable syntax highlighting in the preview
  theme = 'dark',           -- 'dark' or 'light'
  update_on_change = true,  -- THE "VS CODE" FEATURE: updates as you type
})

-- ADD THESE TWO LINES TO FIX THE ERROR:
vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})

later(function()
  add('windwp/nvim-ts-autotag')
  require('nvim-ts-autotag').setup()
end)
now_if_args(function()
  vim.lsp.enable({ 'vtsls' })
end)


