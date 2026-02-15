-- ========================================
-- Plugin: noice.nvim
-- ========================================

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      config = function()
        require("config.notify")
      end,
    },
  },
  config = function()
    require("config.noice")
  end,
}
