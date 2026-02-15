-- ========================================
-- Plugin: lualine.nvim
-- ========================================

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "echasnovski/mini.icons" },
  event = "VeryLazy",
  config = function()
    require("config.lualine")
  end,
}
