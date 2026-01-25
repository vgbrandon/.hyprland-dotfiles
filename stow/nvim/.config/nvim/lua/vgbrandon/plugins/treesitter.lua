return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,

  config = function()
    -- requires
    local treesitter  = require("nvim-treesitter")
    local ts_language = vim.treesitter.language

    -- languages
    local languages   = {
      "bash",
      "c",
      "css",
      "dockerfile",
      "gitignore",
      "graphql",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "prisma",
      "query",
      "svelte",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
    }

    -- setup
    treesitter.setup({})

    -- install parsers
    treesitter.install(languages)

    -- use bash parser for zsh files
    ts_language.register("bash", "zsh")
  end,
}
