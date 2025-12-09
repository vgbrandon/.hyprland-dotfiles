return {
  "goolord/alpha-nvim",
  dependencies = {
    'nvim-mini/mini.icons',
    'nvim-lua/plenary.nvim'
  },
  config = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'
    dashboard.section.header.val = {
      "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
      "⣛⠛⠛⠛⠻⠿⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠟⠛⣛⣛⣋⣉⣉⣉⣉",
      "⡟⠛⠛⢻⠛⠛⠛⣻⠿⣶⠶⠦⣭⣛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣋⣧⠶⡞⠛⢛⣯⠉⢹⡉⣿⠉⠉⢙",
      "⠻⡄⠀⠘⣄⣸⣴⣿⣴⣿⡧⠀⡌⠙⠳⣌⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣡⠞⠋⠘⣄⠻⡇⠀⠀⢠⡾⢄⠇⠀⢀⣾",
      "⣷⣼⣦⡀⠘⠦⣉⠀⠀⢈⡧⠞⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠈⠢⢌⣉⣉⣁⠤⠊⢀⣴⣿⣿",
      "⣿⣿⣿⣿⣶⣄⠀⠉⣽⣧⣤⣤⣤⡤⢤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣤⣿⣶⣭⣤⣿⣿⣿⣿⣿",
      "⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⡇⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿",
    }

    -- Crear secciones personalizadas
    local section_buttons_1 = {
      type = "group",
      val = {
        { type = "text", val = " ACCIONES PRINCIPALES", opts = { hl = "String", position = "center" } },
        { type = "padding", val = 1 },
        dashboard.button("e", "󰈔  Nuevo archivo", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "󰱼  Buscar archivos", ":Telescope find_files <CR>"),
        dashboard.button("r", "󱋡  Recientes", ":Telescope oldfiles <CR>"),
        dashboard.button("g", "󰺯  Buscar texto", ":Telescope live_grep <CR>"),
      }
    }

    local section_buttons_2 = {
      type = "group",
      val = {
        { type = "text", val = "󱁤  HERRAMIENTAS", opts = { hl = "String", position = "center" } },
        { type = "padding", val = 1 },
        dashboard.button("c", "  Configuración", ":e $MYVIMRC<CR>"),
        dashboard.button("t", "  Terminal", ":terminal<CR>"),
        dashboard.button("b", "  Navegador", ":Neotree toggle position=right<CR>"),
        dashboard.button("u", "󱑢  Actualizar", ":Lazy update<CR>"),
        dashboard.button("q", "󰍃  Salir", ":qa<CR>"),
      }
    }

    -- Footer
    local footer_section = {
      type = "text",
      val = function()
        local stats = require("lazy").stats()
        local datetime = os.date("🕐 %H:%M 󰃭 %d/%m/%Y")
        return {
          " ",
          "✨ " .. stats.loaded .. "/" .. stats.count .. " plugins cargados",
          datetime,
          " ",
        }
      end,
      opts = { hl = "Comment", position = "center" }
    }

    -- Layout organizado
    dashboard.config.layout = {
      { type = "padding", val = function() return math.floor(vim.fn.winheight(0) * 0.15) end },
      dashboard.section.header,
      { type = "padding", val = 2 },
      section_buttons_1,
      { type = "padding", val = 2 },
      section_buttons_2,
      { type = "padding", val = 2 },
      footer_section,
    }

    alpha.setup(dashboard.config)
  end
}
