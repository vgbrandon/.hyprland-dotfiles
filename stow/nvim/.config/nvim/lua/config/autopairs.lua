-- ========================================
-- Configuración nvim-autopairs (2025-2026)
-- ========================================

local autopairs = require("nvim-autopairs")

autopairs.setup({
	-- Verificar si el siguiente carácter es un carácter de cierre
	check_ts = true, -- Usar Treesitter
	ts_config = {
		lua = { "string" }, -- No agregar pares en strings de Lua
		javascript = { "template_string" }, -- No agregar en template strings
		java = false, -- Deshabilitar para Java
	},

	-- Deshabilitar en ciertos tipos de archivo
	disable_filetype = { "TelescopePrompt", "vim" },

	-- Configuraciones adicionales
	disable_in_macro = true, -- Deshabilitar en macros
	disable_in_visualblock = false, -- Permitir en visual block
	disable_in_replace_mode = true, -- Deshabilitar en modo replace
	ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=], -- Ignorar estos caracteres después
	enable_moveright = true, -- Mover cursor a la derecha después de insertar
	enable_afterquote = true, -- Agregar par después de comillas
	enable_check_bracket_line = true, -- No agregar par si ya hay uno en la línea
	enable_bracket_in_quote = true, -- Permitir brackets dentro de comillas
	enable_abbr = false, -- Trigger abbreviation
	break_undo = true, -- Romper undo sequence
	check_comma = true, -- Verificar coma
	map_cr = true, -- Mapear <CR> para comportamiento inteligente
	map_bs = true, -- Mapear <BS> para borrar par
	map_c_h = false, -- No mapear <C-h>
	map_c_w = false, -- No mapear <C-w>
})

-- Integración con nvim-cmp
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

-- Reglas personalizadas
local Rule = require("nvim-autopairs.rule")
local cond = require("nvim-autopairs.conds")

-- Agregar espacios entre paréntesis
autopairs.add_rules({
	Rule(" ", " ")
		:with_pair(function(opts)
			local pair = opts.line:sub(opts.col - 1, opts.col)
			return vim.tbl_contains({ "()", "[]", "{}" }, pair)
		end)
		:with_move(cond.none())
		:with_cr(cond.none())
		:with_del(function(opts)
			local col = vim.api.nvim_win_get_cursor(0)[2]
			local context = opts.line:sub(col - 1, col + 2)
			return vim.tbl_contains({ "(  )", "[  ]", "{  }" }, context)
		end),
})

-- Flecha para funciones (JavaScript/TypeScript)
autopairs.add_rules({
	Rule("%(.*%)%s*%=>$", " {  }", { "typescript", "typescriptreact", "javascript", "javascriptreact" })
		:use_regex(true)
		:set_end_pair_length(2),
})
