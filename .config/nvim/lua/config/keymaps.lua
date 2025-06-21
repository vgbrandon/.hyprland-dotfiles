-- Archivo: lua/config/keymaps.lua

-- Función auxiliar para simplificar la creación de mapeos
local map = function(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- Mapeos generales
map("n", "<C-s>", ":w<CR>", { desc = "Guardar archivo" })
map("n", "<leader>q", ":q<CR>", { desc = "Cerrar ventana" })
map("n", "<leader>h", ":nohlsearch<CR>", { desc = "Eliminar resaltado de búsqueda" })

-- Navegación entre ventanas
map("n", "<C-h>", "<C-w>h", { desc = "Mover a la ventana izquierda" })
map("n", "<C-l>", "<C-w>l", { desc = "Mover a la ventana derecha" })
map("n", "<C-j>", "<C-w>j", { desc = "Mover a la ventana inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Mover a la ventana superior" })

-- Redimensionar ventanas
map("n", "<A-Left>", ":vertical resize -2<CR>", { desc = "Reducir ancho de ventana" })
map("n", "<A-Right>", ":vertical resize +2<CR>", { desc = "Aumentar ancho de ventana" })
map("n", "<A-Up>", ":resize +2<CR>", { desc = "Aumentar altura de ventana" })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Reducir altura de ventana" })

-- Navegación entre buffers
map("n", "<Tab>", ":bnext<CR>", { desc = "Siguiente buffer" })
map("n", "<S-Tab>", ":bprevious<CR>", { desc = "Buffer anterior" })

-- Mapeos en modo visual
map("v", "<", "<gv", { desc = "Disminuir indentación" })
map("v", ">", ">gv", { desc = "Aumentar indentación" })

-- Mapeos en modo inserción
map("i", "jk", "<Esc>", { desc = "Salir al modo normal" })
