-- Establecer el líder de teclas antes de cargar los plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Opciones generales
vim.g.have_nerd_font = true
vim.opt.number = true -- Mostrar números de línea
vim.opt.relativenumber = true -- Números de línea relativos
vim.opt.mouse = "a" -- Habilitar el uso del ratón
vim.opt.clipboard = "unnamedplus" -- Usar el portapapeles del sistema
vim.opt.breakindent = true -- Mantener la indentación en líneas largas
vim.opt.undofile = false -- Habilitar archivos de deshacer persistentes
vim.opt.ignorecase = true -- Búsqueda insensible a mayúsculas
vim.opt.smartcase = true -- Búsqueda sensible si hay mayúsculas
vim.opt.updatetime = 250 -- Tiempo de espera para eventos
vim.opt.signcolumn = "yes" -- Mostrar siempre la columna de signos
vim.opt.termguicolors = true -- Habilitar colores verdaderos en la terminal
vim.opt.scrolloff = 8 -- Líneas de margen al desplazarse
vim.opt.sidescrolloff = 8 -- Columnas de margen al desplazarse horizontalmente
vim.opt.splitright = true -- Dividir ventanas verticalmente a la derecha
vim.opt.splitbelow = true -- Dividir ventanas horizontalmente abajo
vim.opt.cursorline = true -- Resaltar la línea actual
vim.opt.wrap = false -- No ajustar líneas largas
vim.opt.swapfile = false -- No usar archivos de intercambio
vim.opt.backup = false -- No crear archivos de respaldo
vim.opt.writebackup = false -- No crear respaldo al guardar
vim.opt.expandtab = true -- Convertir tabulaciones en espacios
vim.opt.shiftwidth = 2 -- Número de espacios por nivel de indentación
vim.opt.tabstop = 2 -- Número de espacios que representa una tabulación
vim.o.numberwidth = 4 --
vim.opt.smartindent = true -- Habilitar indentación inteligente
vim.opt.hlsearch = true -- Resaltar coincidencias de búsqueda
vim.opt.incsearch = true -- Mostrar coincidencias mientras se escribe
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- Opciones de autocompletado
vim.opt.list = true -- Mostrar caracteres invisibles
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Caracteres para espacios, tabulaciones, etc.
vim.opt.fillchars = { eob = " " } -- Reemplaza los ~ de neovim por espacios vacios
vim.opt.laststatus = 3 -- Usa una sola barra de estado
vim.o.showmode = false
vim.opt.confirm = false
