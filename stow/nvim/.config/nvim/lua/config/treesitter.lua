-- ========================================
-- Configuración Treesitter (2025-2026)
-- ========================================

require("nvim-treesitter").setup({
  -- Parsers a instalar automáticamente
  ensure_installed = {
    "bash",
    "c",
    "css",
    "html",
    "javascript",
    "json",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },

  -- Instalar parsers de forma sincrónica (solo aplica a `ensure_installed`)
  sync_install = false,

  -- Instalar automáticamente parsers faltantes cuando entres a un buffer
  auto_install = true,

  -- Lista de parsers a ignorar
  ignore_install = {},

  -- Módulos
  highlight = {
    enable = true,
    
    -- Desactivar treesitter para archivos grandes
    disable = function(lang, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,

    -- Usar highlighting de vim para estos lenguajes además de treesitter
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
  },

  -- Selección incremental
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
})

-- Folding con treesitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false -- No doblar al abrir archivos
vim.opt.foldlevel = 99
