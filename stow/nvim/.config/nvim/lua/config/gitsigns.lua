-- ========================================
-- Configuración Gitsigns (2025-2026)
-- ========================================

require("gitsigns").setup({
	-- Símbolos en el margen
	signs = {
		add = { text = "┃" },
		change = { text = "┃" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	signs_staged = {
		add = { text = "┃" },
		change = { text = "┃" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	-- Símbolos en número de línea
	signcolumn = true, -- Mostrar símbolos en signcolumn
	numhl = false, -- No resaltar números de línea
	linehl = false, -- No resaltar líneas completas
	word_diff = false, -- No mostrar diff por palabra

	-- Configuración de watch
	watch_gitdir = {
		interval = 1000,
		follow_files = true,
	},

	-- Mostrar información de blame
	current_line_blame = false, -- Deshabilitado por defecto (toggle con <leader>gb)
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol", -- Fin de línea
		delay = 500,
		ignore_whitespace = false,
	},
	current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",

	-- Actualización de signos
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil,
	max_file_length = 40000, -- Deshabilitar en archivos muy largos

	-- Preview de diff
	preview_config = {
		border = "rounded",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},

	-- Adjuntar a buffers
	attach_to_untracked = true,

	-- Keymaps
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navegación entre hunks
		map("n", "]h", function()
			if vim.wo.diff then
				return "]c"
			end
			vim.schedule(function()
				gs.next_hunk()
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Next hunk" })

		map("n", "[h", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(function()
				gs.prev_hunk()
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Previous hunk" })

		-- Acciones
		map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
		map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
		map("v", "<leader>hs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Stage hunk" })
		map("v", "<leader>hr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Reset hunk" })
		map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
		map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
		map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
		map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, { desc = "Blame line" })
		map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
		map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
		map("n", "<leader>hD", function()
			gs.diffthis("~")
		end, { desc = "Diff this ~" })
		map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted" })

		-- Text object
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
	end,
})
