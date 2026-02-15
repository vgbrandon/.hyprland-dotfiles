-- ========================================
-- Plugin: nvim-highlight-colors
-- ========================================

return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("config.highlightcolors")
	end,
}
