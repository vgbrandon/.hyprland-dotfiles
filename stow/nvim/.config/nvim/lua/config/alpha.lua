-- ========================================
-- Configuración Alpha-nvim (2025-2026)
-- ========================================

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Header minimalista
dashboard.section.header.val = {
	[[                    N E O V I M                     ]],
}

-- Botones del menú simple
dashboard.section.buttons.val = {
	dashboard.button("f", "  Find File", "<cmd>lua require('fzf-lua').files()<CR>"),
	dashboard.button("r", "  Recent", "<cmd>lua require('fzf-lua').oldfiles()<CR>"),
	dashboard.button("g", "  Grep", "<cmd>lua require('fzf-lua').live_grep()<CR>"),
	dashboard.button("c", "  Config", ":e $MYVIMRC <CR>"),
	dashboard.button("q", "  Quit", ":qa<CR>"),
}

-- Footer simple
local function footer()
	local stats = require("lazy").stats()
	return "  " .. stats.loaded .. "/" .. stats.count .. " plugins"
end

dashboard.section.footer.val = footer()

-- Configuración de colores
dashboard.section.header.opts.hl = "Function"
dashboard.section.buttons.opts.hl = "Keyword"
dashboard.section.footer.opts.hl = "Comment"

-- Función para calcular el padding vertical dinámicamente
local function get_vertical_padding()
	local win_height = vim.api.nvim_win_get_height(0)
	local header_lines = #dashboard.section.header.val
	local button_lines = #dashboard.section.buttons.val
	local footer_lines = 1
	local total_content = header_lines + button_lines + footer_lines + 8 -- +8 por los paddings entre secciones

	local padding = math.floor((win_height - total_content) / 2)
	return math.max(padding, 2) -- Mínimo 2 líneas de padding
end

-- Layout dinámico
dashboard.config.layout = {
	{ type = "padding", val = get_vertical_padding },
	dashboard.section.header,
	{ type = "padding", val = 4 },
	dashboard.section.buttons,
	{ type = "padding", val = 3 },
	dashboard.section.footer,
}

-- Opciones del dashboard
dashboard.config.opts = {
	noautocmd = true,
	redraw_on_resize = true,
}

-- Setup
alpha.setup(dashboard.config)

-- Autocmds
vim.api.nvim_create_autocmd("FileType", {
	pattern = "alpha",
	callback = function()
		vim.opt_local.foldenable = false
		vim.opt_local.cursorline = false
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
	end,
})

-- Recalcular layout cuando cambia el tamaño de la ventana
vim.api.nvim_create_autocmd("VimResized", {
	pattern = "*",
	callback = function()
		if vim.bo.filetype == "alpha" then
			alpha.redraw()
		end
	end,
})
