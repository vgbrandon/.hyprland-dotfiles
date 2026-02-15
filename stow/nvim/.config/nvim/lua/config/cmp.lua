-- ========================================
-- Configuración nvim-cmp (2025-2026)
-- ========================================

local cmp = require("cmp")
local luasnip = require("luasnip")

-- Cargar snippets de friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()

-- Configuración de nvim-cmp
cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},

	-- Ventana de completado
	window = {
		completion = cmp.config.window.bordered({
			border = "single",
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
		}),
		documentation = cmp.config.window.bordered({
			border = "rounded",
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
		}),
	},

	-- Mapeos de teclado
	mapping = cmp.mapping.preset.insert({
		-- Navegación
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

		-- Scroll en la documentación
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),

		-- Abrir/cerrar completado
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),

		-- Confirmar selección
		["<CR>"] = cmp.mapping.confirm({ select = true }),

		-- Super-Tab (Tab para navegar y snippets)
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),

		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),

	-- Fuentes de completado (orden de prioridad)
	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 1000 },
		{ name = "luasnip", priority = 750 },
		{ name = "path", priority = 500 },
	}, {
		{ name = "buffer", priority = 250, keyword_length = 3 },
	}),

	-- Formato de los items
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, item)
			-- Iconos para tipos de completado
			local icons = {
				Text = "󰉿",
				Method = "󰆧",
				Function = "󰊕",
				Constructor = "",
				Field = "󰜢",
				Variable = "󰀫",
				Class = "󰠱",
				Interface = "",
				Module = "",
				Property = "󰜢",
				Unit = "󰑭",
				Value = "󰎠",
				Enum = "",
				Keyword = "󰌋",
				Snippet = "",
				Color = "󰏘",
				File = "󰈙",
				Reference = "󰈇",
				Folder = "󰉋",
				EnumMember = "",
				Constant = "󰏿",
				Struct = "󰙅",
				Event = "",
				Operator = "󰆕",
				TypeParameter = "",
			}

			-- Asignar icono
			if icons[item.kind] then
				item.kind = icons[item.kind] .. " " .. item.kind
			end

			-- Fuente del completado
			local source_names = {
				nvim_lsp = "[LSP]",
				luasnip = "[Snippet]",
				buffer = "[Buffer]",
				path = "[Path]",
			}
			item.menu = source_names[entry.source.name] or "[" .. entry.source.name .. "]"

			return item
		end,
	},

	-- Comportamiento
	experimental = {
		ghost_text = {
			hl_group = "CmpGhostText",
		},
	},
})

-- Completado para búsqueda `/` y `?`
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
	},
})

-- Completado para línea de comandos `:`
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline", keyword_length = 2 },
	}),
	matching = { disallow_symbol_nonprefix_matching = false },
})
