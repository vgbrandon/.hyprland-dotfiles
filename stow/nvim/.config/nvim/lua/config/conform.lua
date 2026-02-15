-- ========================================
-- Configuración Conform (2025-2026)
-- ========================================

require("conform").setup({
	-- Formateadores por tipo de archivo
	formatters_by_ft = {
		-- Web
		javascript = { "prettierd" },
		typescript = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescriptreact = { "prettierd" },
		css = { "prettierd" },
		html = { "prettierd" },
		json = { "prettierd" },
		yaml = { "prettierd" },
		markdown = { "prettierd" },

		-- Python
		python = { "black", "isort" },

		-- Lua
		lua = { "stylua" },

		-- Go
		go = { "gofmt", "goimports" },

		-- Rust
		rust = { "rustfmt" },

		-- Shell
		sh = { "shfmt" },
		bash = { "shfmt" },

		-- C/C++
		c = { "clang-format" },
		cpp = { "clang-format" },

		-- Otros
		["*"] = { "trim_whitespace" }, -- Para todos los archivos
	},

	-- Formato automático al guardar
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},

	-- Notificar cuando no hay formateador disponible
	notify_on_error = true,

	-- Configuración de formateadores individuales
	formatters = {
		shfmt = {
			prepend_args = { "-i", "2" }, -- Indentación de 2 espacios
		},
	},
})
