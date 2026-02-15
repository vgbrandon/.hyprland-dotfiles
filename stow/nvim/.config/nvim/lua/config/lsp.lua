-- ========================================
-- Configuración LSP (2025-2026)
-- ========================================

-- Configuración de diagnósticos
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		source = "if_many",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.HINT] = "",
			[vim.diagnostic.severity.INFO] = "",
		},
	},
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	float = {
		border = "single",
		source = "always",
		header = "",
		prefix = "",
	},
})

-- Configuración de borders para ventanas flotantes
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = "rounded",
})

-- Habilitar inlay hints por defecto (Neovim 0.10+)
if vim.fn.has("nvim-0.10") == 1 then
	vim.lsp.inlay_hint.enable(true)
end

-- Keymaps para LSP usando LspAttach (mejores prácticas 2025)
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		-- Navegación
		map("gd", vim.lsp.buf.definition, "Ir a definición")
		map("gD", vim.lsp.buf.declaration, "Ir a declaración")
		map("gi", vim.lsp.buf.implementation, "Ir a implementación")
		map("gr", vim.lsp.buf.references, "Ver referencias")
		map("gt", vim.lsp.buf.type_definition, "Ir a definición de tipo")

		-- Información
		map("K", vim.lsp.buf.hover, "Hover documentation")
		map("<C-k>", vim.lsp.buf.signature_help, "Signature help")

		-- Acciones
		map("<leader>rn", vim.lsp.buf.rename, "Renombrar")
		map("<leader>ca", vim.lsp.buf.code_action, "Code action")

		-- Diagnósticos
		map("[d", vim.diagnostic.goto_prev, "Diagnóstico anterior")
		map("]d", vim.diagnostic.goto_next, "Diagnóstico siguiente")
		map("<leader>de", vim.diagnostic.open_float, "Ver diagnóstico flotante")
		map("<leader>dl", vim.diagnostic.setloclist, "Lista de diagnósticos")

		-- Inlay hints toggle (si está disponible)
		if vim.lsp.inlay_hint then
			map("<leader>ti", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, "Toggle Inlay Hints")
		end

		-- Resaltar referencias del símbolo bajo el cursor
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client.server_capabilities.documentHighlightProvider then
			local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
				end,
			})
		end
	end,
})

-- Capacidades del cliente LSP (para autocompletado con nvim-cmp si lo añades)
local M = {}

M.capabilities = vim.lsp.protocol.make_client_capabilities()

-- Integrar capacidades de nvim-cmp con LSP
local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if has_cmp then
	M.capabilities = cmp_nvim_lsp.default_capabilities(M.capabilities)
end

return M
