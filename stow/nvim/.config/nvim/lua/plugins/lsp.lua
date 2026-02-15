-- ========================================
-- Plugin: nvim-lspconfig
-- ========================================

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{
			"williamboman/mason.nvim",
			cmd = "Mason",
			keys = { { "<leader>m", "<cmd>Mason<cr>", desc = "Mason" } },
			build = ":MasonUpdate",
			opts = {
				ui = {
					border = "rounded",
					width = 0.8,
					height = 0.8,
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			},
		},
		"williamboman/mason-lspconfig.nvim",
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			config = function()
				require("mason-tool-installer").setup({
					ensure_installed = {
						-- Formateadores
						"prettierd", -- JS/TS/CSS/HTML/JSON/YAML/Markdown (más rápido que prettier)
						"black", -- Python
						"isort", -- Python imports
						"stylua", -- Lua
						"shfmt", -- Shell
						"clang-format", -- C/C++
					},
					auto_update = false,
					run_on_start = true,
				})
			end,
		},
	},
	config = function()
		-- Cargar configuración base de LSP
		require("config.lsp")
		-- Cargar configuración de Mason-LSPConfig
		require("config.mason")
	end,
}
