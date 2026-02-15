-- ========================================
-- Plugin: conform.nvim
-- ========================================

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Formatear archivo o selección",
		},
	},
	config = function()
		require("config.conform")
	end,
}
