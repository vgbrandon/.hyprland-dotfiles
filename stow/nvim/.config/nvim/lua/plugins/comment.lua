-- ========================================
-- Plugin: comment.nvim
-- ========================================

return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring", -- Para JSX/TSX
	},
	config = function()
		require("config.comment")
	end,
}
