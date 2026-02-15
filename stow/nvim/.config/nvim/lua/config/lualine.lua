-- ========================================
-- Configuración lualine (2025-2026)
-- ========================================

local lualine = require("lualine")

-- Función para mostrar solo la primera letra del modo
local function mode_fmt()
	return vim.fn.mode():sub(1, 1)
end

-- Configuración de lualine
lualine.setup({
	options = {
		icons_enabled = true,
		theme = "neopywal", -- Auto detecta el colorscheme (neopywal)
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = true, -- Una statusline global en lugar de una por ventana
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},

	sections = {
		lualine_a = {
			{
				"mode",
				fmt = mode_fmt, -- Solo mostrar primera letra
			},
		},
		lualine_b = {
			"branch",
			"diff",
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				sections = { "error", "warn", "info", "hint" },
				symbols = { error = " ", warn = " ", info = " ", hint = " " },
				colored = true,
				update_in_insert = false,
				always_visible = false,
			},
		},
		lualine_c = {
			{
				"filename",
				file_status = true,
				newfile_status = false,
				path = 1, -- 0 = solo nombre, 1 = relativo, 2 = absoluto, 3 = absoluto con ~
				shorting_target = 40,
				symbols = {
					modified = "[+]",
					readonly = "[-]",
					unnamed = "[Sin nombre]",
					newfile = "[Nuevo]",
				},
			},
		},
		lualine_x = {
			{
				"encoding",
				fmt = string.upper,
			},
			{
				"fileformat",
				symbols = {
					unix = "LF",
					dos = "CRLF",
					mac = "CR",
				},
			},
			"filetype",
		},
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},

	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},

	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = { "lazy", "mason", "fzf" },
})
