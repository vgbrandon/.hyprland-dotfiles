-- ========================================
-- Plugin: neopywal.nvim
-- ========================================

return {
	"RedsXDD/neopywal.nvim",
	name = "neopywal",
	lazy = false,
	priority = 1000,
	config = function()
		require("config.colorscheme")
	end,
}
