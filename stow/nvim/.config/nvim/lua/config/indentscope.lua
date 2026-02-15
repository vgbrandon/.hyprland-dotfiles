-- ========================================
-- Configuración mini.indentscope (2025-2026)
-- ========================================

require("mini.indentscope").setup({
	-- Dibujar la línea de indentación
	draw = {
		delay = 0, -- Sin delay
		animation = require("mini.indentscope").gen_animation.none(), -- Sin animación
	},

	-- Opciones de mapeos (deshabilitados)
	mappings = {
		object_scope = "", -- Deshabilitar textobject
		object_scope_with_border = "",
		goto_top = "",
		goto_bottom = "",
	},

	-- Opciones del símbolo
	options = {
		border = "both", -- Mostrar arriba y abajo del scope
		indent_at_cursor = true, -- Seguir el cursor
		try_as_border = true, -- Intentar usar como borde
	},

	-- Símbolo a usar
	symbol = "│", -- Línea vertical
})

-- Deshabilitar en ciertos tipos de archivo
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"help",
		"alpha",
		"dashboard",
		"neo-tree",
		"Trouble",
		"trouble",
		"lazy",
		"mason",
		"notify",
		"toggleterm",
		"lazyterm",
	},
	callback = function()
		vim.b.miniindentscope_disable = true
	end,
})
