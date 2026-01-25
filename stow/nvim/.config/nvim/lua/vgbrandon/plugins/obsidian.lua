return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Keymaps útiles
    vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Buscar nota" })
    vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Nueva nota" })
    vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianToday<CR>", { desc = "Nota de hoy" })
    vim.keymap.set("n", "<leader>oy", "<cmd>ObsidianYesterday<CR>", { desc = "Nota de ayer" })
    vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Buscar en notas" })
    vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Ver backlinks" })
    vim.keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>", { desc = "Ver links" })
  end,

  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
    "nvim-telescope/telescope.nvim", -- 🔍 búsqueda de notas
    "hrsh7th/nvim-cmp",              -- 🧠 autocompletado de [[notas]]
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/.config/obsidian-vault/vgbrandon",
      },
      --      {
      --        name = "work",
      --        path = "~/vaults/work",
      --      },
    },

    -- see below for full list of options 👇
    mappings = {
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
    },

    ui = {
      enable = true,
    },

    completion = {
      nvim_cmp = true, -- activa autocompletado con [[notas]]
    },
  },
}
