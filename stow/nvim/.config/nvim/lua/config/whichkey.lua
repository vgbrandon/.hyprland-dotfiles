-- ========================================
-- Configuración which-key (2025-2026)
-- ========================================

local which_key = require("which-key")

which_key.setup({
	plugins = {
		marks = true,
		registers = true,
		spelling = {
			enabled = true,
			suggestions = 20,
		},
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},

	win = {
		border = "single",
		padding = { 1, 2 },
	},

	layout = {
		height = { min = 4, max = 25 },
		width = { min = 20, max = 50 },
		spacing = 3,
		align = "left",
	},

	show_help = true,
	show_keys = true,
	disable = {
		buftypes = {},
		filetypes = { "TelescopePrompt" },
	},
})

-- Registrar grupos de teclas con descripción
which_key.add({
	{ "<leader>f", group = "Find (FZF)" },
	{ "<leader>g", group = "Git" },
	{ "<leader>l", group = "Lazy" },
	{ "<leader>m", group = "Mason" },
	{ "<leader>c", group = "Code" },
	{ "<leader>r", group = "Rename" },
	{ "<leader>d", group = "Diagnostics" },
	{ "<leader>t", group = "Toggle" },
	{ "<leader>w", group = "Save" },
	{ "<leader>q", group = "Quit" },
})
