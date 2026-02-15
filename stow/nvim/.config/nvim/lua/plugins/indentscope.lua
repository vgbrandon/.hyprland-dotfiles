-- ========================================
-- Plugin: mini.indentscope
-- ========================================

return {
	"echasnovski/mini.indentscope",
	version = false,
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("config.indentscope")
	end,
}
