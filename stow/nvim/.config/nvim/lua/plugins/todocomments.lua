-- ========================================
-- Plugin: todo-comments.nvim
-- ========================================

return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Siguiente TODO",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Anterior TODO",
		},
		{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Buscar TODOs" },
		{ "<leader>fT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Buscar TODO/FIX/FIXME" },
	},
	config = function()
		require("config.todocomments")
	end,
}
