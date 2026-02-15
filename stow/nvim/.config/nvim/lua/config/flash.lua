-- ========================================
-- Configuración Flash.nvim (2025-2026)
-- ========================================

require("flash").setup({
	-- Labels para los saltos
	labels = "asdfghjklqwertyuiopzxcvbnm",

	-- Configuración de búsqueda
	search = {
		-- Búsqueda incremental
		incremental = true,
		-- Búsqueda hacia adelante/atrás
		forward = true,
		-- Wrap alrededor del documento
		wrap = true,
		-- Modo de búsqueda: exact, search, fuzzy
		mode = "exact",
		-- Multi window search
		multi_window = true,
	},

	-- Configuración de salto
	jump = {
		-- Saltar automáticamente si solo hay un match
		autojump = false,
		-- Saltar en la primera coincidencia
		jumplist = true,
		-- Posición del salto: start, end, range
		pos = "start",
		-- Historia de saltos
		history = false,
		-- Registrar saltos
		register = false,
		-- No auto saltar si hay múltiples matches
		nohlsearch = false,
	},

	-- Configuración de labels
	label = {
		-- Mostrar labels antes del match
		before = true,
		-- Mostrar labels después del match
		after = true,
		-- Reutilizar labels
		reuse = "lowercase",
		-- Distancia mínima entre labels
		min_pattern_length = 0,
		-- Mayúsculas para multi-char labels
		uppercase = true,
		-- Estilo de label
		style = "overlay",
		-- Rainbow labels
		rainbow = {
			enabled = false,
			shade = 5,
		},
	},

	-- Modos de highlight
	modes = {
		-- Modo de búsqueda normal
		search = {
			enabled = true,
			highlight = { backdrop = false },
			jump = { history = true, register = true, nohlsearch = true },
			search = {
				multi_window = true,
				forward = true,
				wrap = true,
				incremental = true,
			},
		},
		-- Modo de carácter (como f, t)
		char = {
			enabled = true,
			-- Configuración para f, F, t, T
			keys = { "f", "F", "t", "T" },
			search = { wrap = false },
			highlight = { backdrop = true },
			jump = { register = false },
			-- Mostrar labels solo después de algunos caracteres
			multi_line = true,
			label = { exclude = "hjkliardc" },
			-- Autohide después de un tiempo
			autohide = false,
			jump_labels = true,
		},
		-- Modo Treesitter
		treesitter = {
			enabled = true,
			labels = "abcdefghijklmnopqrstuvwxyz",
			jump = { pos = "range" },
			search = { incremental = false },
			label = { before = true, after = true, style = "inline" },
			highlight = {
				backdrop = false,
				matches = false,
			},
		},
	},

	-- Prompt de búsqueda
	prompt = {
		enabled = true,
		prefix = { { "⚡", "FlashPromptIcon" } },
		win_config = {
			relative = "editor",
			width = 1,
			height = 1,
			row = -1,
			col = 0,
			zindex = 1000,
		},
	},

	-- Configuración de resaltado
	highlight = {
		-- Backdrop para oscurecer el fondo
		backdrop = true,
		-- Grupos de highlight
		groups = {
			match = "FlashMatch",
			current = "FlashCurrent",
			backdrop = "FlashBackdrop",
			label = "FlashLabel",
		},
	},
})

-- Configurar colores usando el tema actual
vim.api.nvim_set_hl(0, "FlashLabel", { link = "Error" }) -- Rojo brillante del tema
vim.api.nvim_set_hl(0, "FlashMatch", { link = "Search" }) -- Color de búsqueda del tema
vim.api.nvim_set_hl(0, "FlashCurrent", { link = "IncSearch" }) -- Color de búsqueda incremental
vim.api.nvim_set_hl(0, "FlashBackdrop", { link = "Comment" }) -- Gris del tema
