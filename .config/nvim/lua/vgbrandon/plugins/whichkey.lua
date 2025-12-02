return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    preset = "classic",
    spec = {
      -- Para agregar mapeos personzalizados
      --  { "<leader>p", group = "Pomodoro", icon = { icon = " ", color = "red" } },
      --  { "<leader>ps", "<cmd>TimerSession pomodoro<cr>", desc = "Start Session", icon = { icon = "󱫠 ", color = "red" } },
      --  { "<leader>pt", "<cmd>TimerStart 25m Work<cr>", desc = "Start 25m Timer", icon = { icon = "󱫠 ", color = "red" } },
      --  { "<leader>pp", "<cmd>TimerPause<cr>", desc = "Pause Timer", icon = { icon = "󱫞 ", color = "red" } },
      --  { "<leader>pr", "<cmd>TimerResume<cr>", desc = "Resume Timer", icon = { icon = "󱫌 ", color = "red" } },
      --  { "<leader>px", "<cmd>TimerStop<cr>", desc = "Stop Timer", icon = { icon = "󱫪 ", color = "red" } },
    }
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },

}
