-- ========================================
-- Configuración nvim-surround (2025-2026)
-- ========================================

require("nvim-surround").setup({
	-- Configuración de keymaps
	keymaps = {
		insert = "<C-g>s", -- Insertar surround en modo insert
		insert_line = "<C-g>S", -- Insertar surround en línea completa
		normal = "ys", -- Agregar surround en modo normal
		normal_cur = "yss", -- Agregar surround a línea actual
		normal_line = "yS", -- Agregar surround con nueva línea
		normal_cur_line = "ySS", -- Agregar surround a línea con nueva línea
		visual = "S", -- Agregar surround en modo visual
		visual_line = "gS", -- Agregar surround en modo visual con línea
		delete = "ds", -- Eliminar surround
		change = "cs", -- Cambiar surround
		change_line = "cS", -- Cambiar surround con nueva línea
	},

	-- Surrounds personalizados
	surrounds = {
		-- Ejemplo de surrounds personalizados
		-- ["("] = { add = { "(", ")" } },
		-- ["{"] = { add = { "{", "}" } },
	},

	-- Alias para surrounds comunes
	aliases = {
		["a"] = ">", -- 'a' para angle brackets <>
		["b"] = ")", -- 'b' para parentheses ()
		["B"] = "}", -- 'B' para braces {}
		["r"] = "]", -- 'r' para brackets []
		["q"] = { '"', "'", "`" }, -- 'q' para cualquier tipo de comillas
		["s"] = { "}", "]", ")", ">", '"', "'", "`" }, -- 's' para cualquier surround
	},

	-- Resaltar surrounds al agregar/cambiar
	highlight = {
		duration = 0, -- Duración del highlight (0 = deshabilitado)
	},

	-- Mover cursor después de operación
	move_cursor = "begin", -- "begin" | "end" | false

	-- Indentación
	indent_lines = function(start, stop)
		local b = vim.bo
		-- Solo indentar para ciertos tipos de archivo
		if b.filetype == "python" or b.filetype == "javascript" or b.filetype == "typescript" then
			return true
		end
		return false
	end,
})
