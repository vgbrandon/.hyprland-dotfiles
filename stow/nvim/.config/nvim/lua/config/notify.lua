-- ========================================
-- Configuración nvim-notify (2025-2026)
-- ========================================

require("notify").setup({
  -- Estilo de renderizado
  render = "wrapped-compact",
  
  -- Posición de las notificaciones
  top_down = false, -- Apilar de abajo hacia arriba
  
  -- Stages de animación
  stages = "fade",
  
  -- Timeout por defecto (en ms)
  timeout = 3000,
  
  -- Ancho máximo
  max_width = 50,
  max_height = 10,
  
  -- Nivel mínimo de notificación
  level = vim.log.levels.INFO,
  
  -- Iconos Nerd Font completos
  icons = {
    ERROR = "󰅚",
    WARN = "󰀪",
    INFO = "󰋽",
    DEBUG = "",
    TRACE = "✎",
  },
  
  -- Tiempo entre frames de animación
  fps = 30,
  
  -- Background opacity
  background_colour = "Normal",
  
  -- Habilitar iconos en el título
  on_open = function(win)
    vim.api.nvim_win_set_config(win, { focusable = false })
  end,
})

-- Establecer nvim-notify como el handler por defecto
vim.notify = require("notify")
