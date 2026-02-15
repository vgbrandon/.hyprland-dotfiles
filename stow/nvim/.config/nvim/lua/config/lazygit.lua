-- ========================================
-- Configuración LazyGit (2025-2026)
-- ========================================

-- Configuración de LazyGit
vim.g.lazygit_floating_window_winblend = 0 -- Transparencia de la ventana (0-100)
vim.g.lazygit_floating_window_scaling_factor = 0.9 -- Tamaño de la ventana (0.1-1.0)
vim.g.lazygit_floating_window_border_chars = { "┌", "─", "┐", "│", "┘", "─", "└", "│" }
vim.g.lazygit_floating_window_use_plenary = 0 -- Usar plenary para ventana flotante
vim.g.lazygit_use_neovim_remote = 1 -- Usar neovim-remote para abrir archivos desde lazygit
vim.g.lazygit_use_custom_config_file_path = 0 -- No usar config personalizado

-- Configurar tema de LazyGit para que coincida con neopywal
-- LazyGit usa los colores del terminal automáticamente
