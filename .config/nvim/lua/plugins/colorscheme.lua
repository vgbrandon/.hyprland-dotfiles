return {
	"sainnhe/gruvbox-material",
	lazy = false,
	priority = 1000,
	config = function()
		-- Optionally configure and load the colorscheme
		-- directly inside the plugin declaration.
		vim.g.gruvbox_material_enable_italic = true
		vim.g.gruvbox_material_background = "hard"
		vim.cmd.colorscheme("gruvbox-material")
		-- Highlight para Neo-tree (gruvbox-material)
		vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "#1d2021" })
		vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "#1d2021" })
		-- Fondo del panel de estado y título
		vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "#1d2021", fg = "#1d2021" }) -- elimina el símbolo `~`
		vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { bg = "#1d2021", fg = "#1d2021" }) -- línea divisoria
		vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = "#32302f" }) -- línea bajo el cursor
	end,
}
