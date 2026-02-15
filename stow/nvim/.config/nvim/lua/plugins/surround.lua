-- ========================================
-- Plugin: nvim-surround
-- ========================================

return {
	"kylechui/nvim-surround",
	version = "*", -- Usar última versión estable
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("config.surround")
	end,
}
