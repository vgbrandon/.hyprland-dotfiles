-- ========================================
-- Plugin: fzf-lua
-- ========================================

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    -- Búsqueda de archivos
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Buscar archivos" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Archivos recientes" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Buscar texto (grep)" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Buscar palabra bajo cursor" },
    
    -- Búsqueda de buffers y ayuda
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buscar buffers" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Buscar ayuda" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Buscar keymaps" },
    
    -- Git
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
    
    -- LSP
    { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Símbolos del documento" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnósticos" },
  },
  config = function()
    require("config.fzf")
  end,
}
