-- ========================================
-- Opciones Generales de Neovim
-- ========================================

local opt = vim.opt

-- Números de línea
opt.number = true
opt.relativenumber = true

-- Indentación
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Búsqueda
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Apariencia
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Optimizaciones de rendimiento
opt.redrawtime = 1500 -- Tiempo máximo de redibujado en ms

-- Comportamiento
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.splitright = true
opt.splitbelow = true
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undofile = false 
opt.updatetime = 250
opt.timeoutlen = 300

-- Backspace
opt.backspace = "indent,eol,start"

-- Completado
opt.completeopt = "menu,menuone,noselect"

-- Codificación
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
