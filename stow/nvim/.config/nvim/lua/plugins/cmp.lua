-- ========================================
-- Plugin: nvim-cmp (Autocompletado)
-- ========================================

return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    -- Fuentes de completado
    "hrsh7th/cmp-nvim-lsp",     -- LSP
    "hrsh7th/cmp-buffer",       -- Buffer
    "hrsh7th/cmp-path",         -- Rutas del sistema
    "hrsh7th/cmp-cmdline",      -- Línea de comandos
    
    -- Snippets (requerido por nvim-cmp)
    "L3MON4D3/LuaSnip",         -- Motor de snippets
    "saadparwaiz1/cmp_luasnip", -- Integración LuaSnip con cmp
    "rafamadriz/friendly-snippets", -- Colección de snippets
  },
  config = function()
    require("config.cmp")
  end,
}
