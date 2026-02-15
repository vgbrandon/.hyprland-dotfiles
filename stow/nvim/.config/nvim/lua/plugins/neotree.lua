-- ========================================
-- Plugin: neo-tree.nvim
-- ========================================

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"echasnovski/mini.icons",
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle explorador de archivos" },
		{ "<leader>o", "<cmd>Neotree focus<cr>", desc = "Enfocar explorador" },
	},
	config = function()
		require("config.neotree")
	end,
}
