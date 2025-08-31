return {
  --Antes que nada debemos de tener instalado pnpm para instalar
  --live-server (se agrego en el instalador) luego ejecutamos
  --pnpm setup y luego source /home/vgbrandon/.zshrc y al final
  --cerramos todas las terminales y volvemos a abrir
	"barrett-ruth/live-server.nvim",
	build = "pnpm add -g live-server",
	cmd = { "LiveServerStart", "LiveServerStop" },
	config = function()
		require("live-server").setup({
			args = {
				"--browser=firefox",
			},
		})
	end,
}
