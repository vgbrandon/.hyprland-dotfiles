-- ========================================
-- Configuración todo-comments (2025-2026)
-- ========================================

require("todo-comments").setup({
	signs = true, -- Mostrar iconos en el margen (sign column)
	sign_priority = 8, -- Prioridad del signo

	-- Palabras clave a resaltar
	keywords = {
		FIX = {
			icon = " ", -- Icono de bug
			color = "error", -- Rojo
			alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- Alternativas
		},
		TODO = {
			icon = " ", -- Icono de check
			color = "info", -- Azul
		},
		HACK = {
			icon = " ", -- Icono de fuego
			color = "warning", -- Naranja
		},
		WARN = {
			icon = " ", -- Icono de advertencia
			color = "warning", -- Naranja
			alt = { "WARNING", "XXX" },
		},
		PERF = {
			icon = " ", -- Icono de cohete
			color = "default", -- Color por defecto
			alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" },
		},
		NOTE = {
			icon = " ", -- Icono de nota
			color = "hint", -- Verde/cyan
			alt = { "INFO" },
		},
		TEST = {
			icon = "⏲ ", -- Icono de reloj
			color = "test", -- Magenta
			alt = { "TESTING", "PASSED", "FAILED" },
		},
	},

	gui_style = {
		fg = "NONE", -- Estilo del texto: NONE, BOLD, ITALIC
		bg = "BOLD", -- Estilo del fondo: NONE, BOLD
	},

	merge_keywords = true, -- Mergear con keywords por defecto

	-- Resaltar toda la línea o solo la keyword
	highlight = {
		multiline = true, -- Soporta comentarios multilínea
		multiline_pattern = "^.", -- Patrón para multilínea
		multiline_context = 10, -- Líneas extra a considerar
		before = "", -- Resaltar antes de la keyword
		keyword = "wide", -- "fg", "bg", "wide", "wide_bg", "wide_fg"
		after = "fg", -- Resaltar después de la keyword
		pattern = [[.*<(KEYWORDS)\s*:]], -- Patrón de búsqueda (Vim regex)
		comments_only = true, -- Solo en comentarios
		max_line_len = 400, -- Ignorar líneas muy largas
		exclude = {}, -- Excluir tipos de archivo
	},

	-- Colores personalizados
	colors = {
		error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
		warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
		info = { "DiagnosticInfo", "#2563EB" },
		hint = { "DiagnosticHint", "#10B981" },
		default = { "Identifier", "#7C3AED" },
		test = { "Identifier", "#FF00FF" },
	},

	search = {
		command = "rg",
		args = {
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
		},
		pattern = [[\b(KEYWORDS):]], -- Patrón para ripgrep (regex)
	},
})
