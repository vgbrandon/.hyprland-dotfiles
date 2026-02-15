-- ========================================
-- Configuración fzf-lua (2025-2026)
-- ========================================

require("fzf-lua").setup({
	-- Configuración global
	"default-title",

	winopts = {
		height = 0.85,
		width = 0.80,
		row = 0.35,
		col = 0.50,
		border = "single",
		preview = {
			layout = "flex",
			flip_columns = 120,
			scrollbar = "float",
		},
	},

	-- Keymaps dentro de fzf
	keymap = {
		builtin = {
			["<C-/>"] = "toggle-help",
			["<C-d>"] = "preview-page-down",
			["<C-u>"] = "preview-page-up",
		},
		fzf = {
			["ctrl-q"] = "select-all+accept",
			["ctrl-a"] = "toggle-all",
		},
	},

	-- Configuración de archivos
	files = {
		prompt = "Files❯ ",
		cwd_prompt = true,
		cwd_prompt_shorten_len = 32,
		cwd_prompt_shorten_val = 1,
		find_opts = [[-type f -not -path '*/\.git/*' -printf '%P\n']],
		rg_opts = "--color=never --files --hidden --follow -g '!.git'",
		fd_opts = "--color=never --type f --hidden --follow --exclude .git",
	},

	-- Configuración de grep
	grep = {
		prompt = "Rg❯ ",
		input_prompt = "Grep For❯ ",
		rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
	},

	-- LSP
	lsp = {
		prompt_postfix = "❯ ",
		symbols = {
			symbol_style = 1, -- 1: icon+kind, 2: icon, 3: kind
		},
	},

	-- Previewers
	previewers = {
		builtin = {
			extensions = {
				["png"] = { "chafa" },
				["jpg"] = { "chafa" },
				["jpeg"] = { "chafa" },
			},
		},
	},
})
