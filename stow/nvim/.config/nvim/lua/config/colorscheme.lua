-- ========================================
-- Configuración de Colorscheme (Neopywal)
-- ========================================

-- Configurar neopywal
require("neopywal").setup({
	-- Usar backend de pywal por defecto
	use_wallust = false,

	-- Estilos de código
	transparent_background = true,

	-- Plugins soportados (habilitar solo los que uses)
	plugins = {
		treesitter = true,
		telescope = false,
		nvim_cmp = true,
		lsp = true,
		mason = true,
	},

	-- Deshabilitar syntax highlighting por defecto para mejor rendimiento
	default_fileformats = false,
})

-- Aplicar el colorscheme
vim.cmd.colorscheme("neopywal")
