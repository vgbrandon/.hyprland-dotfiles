-- ========================================
-- Configuración Mason-LSPConfig (2025-2026)
-- ========================================

local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local lsp = require("config.lsp")

-- Configurar Mason-LSPConfig con handlers
mason_lspconfig.setup({
  -- Lista de servidores LSP a instalar automáticamente
  ensure_installed = {
    "lua_ls",
    "ts_ls",
  },
  
  -- Handlers para configurar servidores (nueva API Mason 2.0)
  handlers = {
    -- Handler por defecto para todos los servidores
    function(server_name)
      lspconfig[server_name].setup({
        capabilities = lsp.capabilities,
      })
    end,

    -- Handlers personalizados para servidores específicos
    ["lua_ls"] = function()
      lspconfig.lua_ls.setup({
        capabilities = lsp.capabilities,
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                vim.env.VIMRUNTIME,
                "${3rd}/luv/library",
              },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
            hint = {
              enable = true,
              setType = true,
            },
          },
        },
      })
    end,
  },
})
