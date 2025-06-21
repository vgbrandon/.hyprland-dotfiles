return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	---@class snacks.indent.Config
	---@field enabled? boolean

	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = false },
		dashboard = { enabled = true },
		explorer = { enabled = false },
		indent = {
			priority = 1,
			enabled = true, -- enable indent guides
			char = "│",
			only_scope = false, -- only show indent guides of the scope
			only_current = false, -- only show indent guides in the current window
			-- can be a list of hl groups to cycle through
			hl = {
				"SnacksIndent1",
				"SnacksIndent2",
				"SnacksIndent3",
				"SnacksIndent4",
				"SnacksIndent5",
				"SnacksIndent6",
				"SnacksIndent7",
				"SnacksIndent8",
			},
			scope = {
				enabled = true, -- enable highlighting the current scope
				priority = 200,
				char = "│",
				underline = false, -- underline the start of the scope
				only_current = false, -- only show scope in the current window
				hl = {
					"SnacksIndent1",
					"SnacksIndent2",
					"SnacksIndent3",
					"SnacksIndent4",
					"SnacksIndent5",
					"SnacksIndent6",
					"SnacksIndent7",
					"SnacksIndent8",
				},
			},
		},
		input = { enabled = false },
		picker = { enabled = false },
		scope = { enabled = true },
		notifier = { enabled = false },
		quickfile = { enabled = false },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = false },
	},
}
