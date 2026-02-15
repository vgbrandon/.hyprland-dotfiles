-- ========================================
-- Configuración nvim-highlight-colors (2025-2026)
-- ========================================

require("nvim-highlight-colors").setup({
	-- Modo de renderizado
	render = "virtual", -- 'background' | 'foreground' | 'virtual'

	-- Posición del símbolo virtual (ANTES del color)
	virtual_symbol = "󱓻", -- Círculo relleno (no tiene borde redondeado, pero es el más cercano)
	virtual_symbol_prefix = "",
	virtual_symbol_suffix = " ",
	virtual_symbol_position = "inline", -- 'inline' muestra antes del texto

	-- Habilitar todos los formatos
	enable_hex = true, -- #FFFFFF
	enable_short_hex = true, -- #fff
	enable_rgb = true, -- rgb(0 0 0)
	enable_hsl = true, -- hsl(150deg 30% 40%)
	enable_var_usage = true, -- var(--color)
	enable_named_colors = true, -- blue, red, green, etc.
	enable_tailwind = false, -- bg-blue-500 (desactivado)

	-- Excluir tipos de archivo
	exclude_filetypes = {
		"lazy",
		"mason",
		"help",
	},

	-- Excluir buffers
	exclude_buftypes = {},
})
