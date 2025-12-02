return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- add any options here
    views = {
      border = { style = "none" },
      popup = { border = { style = { "single" } } },
      cmdline_popupmenu = {
        border = { style = { border = "single" } },
      },
      -- Solo este sirvio para cambiar a bordes rectos, los demas no se
      cmdline_popup = {
        border = { style = "single" }
      }
    }
  },

  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    {
      "rcarriga/nvim-notify",
      opts = {
        background_colour = function()
          -- Usa el color de fondo del tema activo o negro si no existe
          local normal = vim.api.nvim_get_hl_by_name("Normal", true)
          return normal and string.format("#%06x", normal.background or 0) or "#000000"
        end,

        on_open = function(win)
          local config = vim.api.nvim_win_get_config(win)
          config.border = "single"
          vim.api.nvim_win_set_config(win, config)
        end
      },
    },
  },
}
