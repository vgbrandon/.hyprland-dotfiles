-- ========================================
-- Keymaps Personalizados
-- ========================================

local keymap = vim.keymap

-- Líder key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modo normal --

-- Navegación entre ventanas
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Ir a ventana izquierda" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Ir a ventana inferior" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Ir a ventana superior" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Ir a ventana derecha" })

-- Redimensionar ventanas
keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Aumentar altura" })
keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Disminuir altura" })
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Disminuir anchura" })
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Aumentar anchura" })

-- Navegación entre buffers
keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Siguiente buffer" })
keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Buffer anterior" })

-- Guardar y salir
keymap.set("n", "<leader>w", ":w<CR>", { desc = "Guardar archivo" })
keymap.set("n", "<leader>q", ":q<CR>", { desc = "Salir" })
keymap.set("n", "<leader>Q", ":qa!<CR>", { desc = "Salir sin guardar" })

-- Limpiar resaltado de búsqueda
keymap.set("n", "<Esc>", ":nohl<CR>", { desc = "Limpiar búsqueda" })

-- Mover líneas
keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Mover línea abajo" })
keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Mover línea arriba" })

-- Modo visual --

-- Mantener selección al indentar
keymap.set("v", "<", "<gv", { desc = "Indentar izquierda" })
keymap.set("v", ">", ">gv", { desc = "Indentar derecha" })

-- Mover bloques de texto
keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Mover bloque abajo" })
keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Mover bloque arriba" })

-- Pegar sin sobrescribir el registro
keymap.set("v", "p", '"_dP', { desc = "Pegar sin sobrescribir" })

-- Modo inserción --

-- Salir del modo inserción
keymap.set("i", "jk", "<ESC>", { desc = "Salir a modo normal" })
keymap.set("i", "kj", "<ESC>", { desc = "Salir a modo normal" })

-- Terminal --

-- Abrir terminal (con tamaño ajustado y modo inserción)
keymap.set("n", "<leader>th", ":split | resize 15 | terminal<CR>", { desc = "Terminal horizontal (abajo)" })
keymap.set("n", "<leader>tv", ":vsplit | vertical resize 80 | terminal<CR>", { desc = "Terminal vertical (derecha)" })

-- Salir del modo terminal
keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Salir modo terminal" })
keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Salir modo terminal" })

-- Navegación en modo terminal
keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Ir a ventana izquierda" })
keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Ir a ventana inferior" })
keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Ir a ventana superior" })
keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Ir a ventana derecha" })

-- Auto-entrar en modo inserción al abrir terminal o cambiar a ventana de terminal
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
	pattern = "term://*",
	callback = function()
		vim.cmd("startinsert")
	end,
})
