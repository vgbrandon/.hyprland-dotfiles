-- ========================================
-- Configuración Comment.nvim (2025-2026)
-- ========================================

require("Comment").setup({
	-- Agregar espacio entre comentario y línea
	padding = true,

	-- Mantener cursor en la misma posición
	sticky = true,

	-- Ignorar líneas vacías
	ignore = "^$",

	-- Mapeos en modo normal
	toggler = {
		line = "gcc", -- Comentar/descomentar línea actual
		block = "gbc", -- Comentar/descomentar bloque
	},

	-- Mapeos en modo operador
	opleader = {
		line = "gc", -- Comentar líneas con motion (ej: gc3j comenta 3 líneas abajo)
		block = "gb", -- Comentar bloque con motion
	},

	-- Mapeos extra en modo visual
	extra = {
		above = "gcO", -- Comentar línea arriba
		below = "gco", -- Comentar línea abajo
		eol = "gcA", -- Comentar al final de línea
	},

	-- Habilitar mapeos básicos
	mappings = {
		basic = true, -- gcc, gbc, gc[motion], gb[motion]
		extra = true, -- gco, gcO, gcA
	},

	-- Función pre-hook para determinar el tipo de comentario
	-- Integración con treesitter para JSX/TSX
	pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),

	-- Función post-hook (se ejecuta después de comentar)
	post_hook = nil,
})
