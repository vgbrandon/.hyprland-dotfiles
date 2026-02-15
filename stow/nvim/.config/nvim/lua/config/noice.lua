-- ========================================
-- Configuración Noice (2025-2026)
-- ========================================

require("noice").setup({
	lsp = {
		-- Sobrescribir markdown rendering para que lsp use Treesitter
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},

	-- Presets para configuración rápida
	presets = {
		bottom_search = false, -- NO usar barra de búsqueda en la parte inferior - usar popup
		command_palette = true, -- Posicionar cmdline y popupmenu juntos
		long_message_to_split = true, -- Mensajes largos se enviarán a un split
		inc_rename = false, -- Habilita un diálogo de input para inc-rename.nvim
		lsp_doc_border = true, -- Agregar un borde a las ventanas flotantes de documentación
	},

	-- Configuración de comandos
	cmdline = {
		enabled = true,
		view = "cmdline_popup", -- vista de cmdline (cmdline|popup|split)
		opts = {
			buf_options = { filetype = "vim" },
		},
		format = {
			cmdline = { pattern = "^:", icon = "", lang = "vim" },
			search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
			search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
			filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
			lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
			help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
			input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
		},
	},

	-- Configuración de mensajes
	messages = {
		enabled = true,
		view = "mini", -- vista mini (como mensajes normales pero mejorados)
		view_error = "notify", -- vista para errores
		view_warn = "notify", -- vista para warnings
		view_history = "messages", -- vista para :messages
		view_search = false, -- deshabilitar virtualtext para búsqueda
	},

	-- Configuración de popupmenu (autocompletado de comandos)
	popupmenu = {
		enabled = true,
		backend = "nui", -- backend a usar para mostrar el popupmenu
		kind_icons = {}, -- usar mini.icons
	},

	-- Configuración de notificaciones
	notify = {
		enabled = true,
		view = "notify",
	},

	-- Configuración de LSP
	lsp = {
		progress = {
			enabled = true,
			format = "lsp_progress",
			format_done = "lsp_progress_done",
			throttle = 1000 / 30, -- frecuencia de actualización
			view = "mini",
		},
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
		hover = {
			enabled = true,
			silent = false,
			view = nil,
			opts = {},
		},
		signature = {
			enabled = true,
			auto_open = {
				enabled = true,
				trigger = true,
				luasnip = true,
				throttle = 50,
			},
			view = nil,
			opts = {},
		},
		message = {
			enabled = true,
			view = "notify",
			opts = {},
		},
		documentation = {
			view = "hover",
			opts = {
				lang = "markdown",
				replace = true,
				render = "plain",
				format = { "{message}" },
				win_options = { concealcursor = "n", conceallevel = 3 },
			},
		},
	},

	-- Rutas para personalizar el comportamiento
	routes = {
		{
			filter = {
				event = "msg_show",
				kind = "",
				find = "written",
			},
			opts = {
				title = "󰆓 Guardado",
				icon = "󰆓",
			},
			view = "notify",
		},
		{
			filter = {
				event = "msg_show",
				find = "search hit BOTTOM",
			},
			opts = {
				title = " Búsqueda",
				icon = "",
			},
			view = "notify",
		},
		{
			filter = {
				event = "msg_show",
				find = "search hit TOP",
			},
			opts = {
				title = " Búsqueda",
				icon = "",
			},
			view = "notify",
		},
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
				},
			},
			opts = {
				title = " Información",
				icon = "",
			},
			view = "notify",
		},
	},

	-- Views
	views = {
		cmdline_popup = {
			position = {
				row = 5,
				col = "50%",
			},
			size = {
				width = 60,
				height = "auto",
			},
		},
		popupmenu = {
			relative = "editor",
			position = {
				row = 8,
				col = "50%",
			},
			size = {
				width = 60,
				height = 10,
			},
			border = {
				style = "single",
				padding = { 0, 1 },
			},
			win_options = {
				winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
			},
		},
	},
})
