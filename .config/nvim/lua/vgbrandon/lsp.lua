-- Ahora aqui ya no cargaras manualmente los servidores de cada lenguaje sino que 
-- puedes usar este archivo para crear keymaps que se podran usar una vez carguen los servidores instalados
local severity = vim.diagnostic.severity

vim.diagnostic.config({
  signs = {
    text = {
      [severity.ERROR] = " ",
      [severity.WARN] = " ",
      [severity.HINT] = "󰠠 ",
      [severity.INFO] = " ",
    }
  }
})
