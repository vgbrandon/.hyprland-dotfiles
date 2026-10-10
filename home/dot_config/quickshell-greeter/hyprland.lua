-- Hyprland mínimo para la pantalla de inicio de sesión (greetd, usuario "greeter").
-- Se instala en /etc/greetd/hyprland.lua (ver install.sh). Solo arranca el greeter
-- de Quickshell; cuando este lanza la sesión y se cierra, este Hyprland sale.

-- Los mismos monitores que la sesión normal (copia de ~/.config/hypr/monitors.lua)
require("monitors")

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},
	-- Mismo motivo que en la sesión normal (cursor corrupto entre GPUs)
	cursor = {
		no_hardware_cursors = true,
	},
	-- La misma distribución de teclado, para escribir la contraseña igual
	input = {
		kb_layout = "us",
		kb_variant = "engrammer",
	},
})

hl.on("hyprland.start", function()
	-- El registro va a /tmp para poder revisarlo desde la sesión normal
	hl.exec_cmd("sh -c 'quickshell -p /etc/greetd/quickshell > /tmp/qs-greeter.log 2>&1; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
