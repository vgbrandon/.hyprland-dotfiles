#!/usr/bin/env bash
set -euo pipefail

# Pantalla de carga al arrancar Arch (Plymouth) con el tema "quickshell": logo de
# Arch con el color del texto del escritorio. Lo ejecuta chezmoi cuando
# cambia algo; también se puede correr a mano. Reconstruye el initramfs.

src="$HOME/.config/plymouth-theme"
theme=/usr/share/plymouth/themes/quickshell
shared=/var/lib/qs-greeter/theme.json
params=(quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0)

if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
  echo "[WARN] Plymouth no está instalado. Saltando la pantalla de carga."
  exit 0
fi

# --- Imágenes con los colores del tema (los que comparte Quickshell) ---
color() { python3 -I -c "import json,sys
try: print(json.load(open('$shared'))['scheme'][sys.argv[1]])
except Exception: print(sys.argv[2])" "$1" "$2"; }
text="$(color on_surface '#e6e1e5')"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# Logo de Arch (glifo md-arch de la Nerd Font)
cat > "$tmp/logo.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160">
  <text x="80" y="80" text-anchor="middle" dominant-baseline="central"
        font-family="JetBrainsMono Nerd Font Propo" font-size="120" fill="$text">&#xF08C7;</text>
</svg>
SVG
rsvg-convert "$tmp/logo.svg" -o "$tmp/logo.png"

# --- Tema ---
sudo rm -rf "$theme"
sudo install -d -m 755 "$theme"
sudo install -m 644 "$src"/quickshell.{plymouth,script} "$tmp"/logo.png "$theme"/

# Sin imagen en el UKI: se veía antes que esta pantalla, a baja resolución (aún sin
# controlador gráfico), y quedaban dos logos seguidos
preset=/etc/mkinitcpio.d/linux.preset
if [ -f "$preset" ] && grep -qE -- '--splash [^ "]+' "$preset"; then
  sudo sed -i -E 's#[ ]?--splash [^ "]+##' "$preset"
  echo "[OK] Imagen de arranque del UKI quitada de $preset."
fi

# --- Hook de Plymouth en el initramfs (después de udev) ---
if ! grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
  sudo sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' /etc/mkinitcpio.conf
  echo "[OK] Hook plymouth añadido a /etc/mkinitcpio.conf."
fi

# --- Parámetros del kernel (ocultan los mensajes y activan la pantalla) ---
# Con imagen unificada del kernel (UKI), las opciones van dentro del .efi y salen
# de /etc/kernel/cmdline (se aplican al reconstruirlo, al final)
if [ -f /etc/kernel/cmdline ]; then
  for p in "${params[@]}"; do
    if ! grep -qE "(^| )${p//./\\.}( |$)" /etc/kernel/cmdline; then
      sudo sed -i "1 s/\$/ ${p}/" /etc/kernel/cmdline
    fi
  done
  echo "[OK] Parámetros del kernel (UKI) en /etc/kernel/cmdline:"
  sed 's/^/       /' /etc/kernel/cmdline
fi

# Sin UKI, rEFInd los pasa desde refind_linux.conf
conf=/boot/refind_linux.conf
if sudo [ -f "$conf" ]; then
  for p in "${params[@]}"; do
    # Solo en las entradas normales (no en la de modo de usuario único)
    sudo sed -i -E "/single/! { /[\" ]${p//./\\.}[\" ]/! s/^(\"[^\"]*\"[[:space:]]+\"[^\"]*)\"/\1 ${p}\"/ }" "$conf"
  done
  echo "[OK] Parámetros del kernel en $conf:"
  sudo grep -v '^#' "$conf" | sed 's/^/       /'
else
  [ -f /etc/kernel/cmdline ] || echo "[WARN] No existe $conf: añade a mano a las opciones del kernel: ${params[*]}"
fi

# rEFInd: sin texto al arrancar el sistema elegido
refind=/boot/EFI/refind/refind.conf
if sudo [ -f "$refind" ] && ! sudo grep -qE '^use_graphics_for' "$refind"; then
  echo "use_graphics_for linux,windows" | sudo tee -a "$refind" >/dev/null
  echo "[OK] rEFInd arranca los sistemas sin texto (use_graphics_for)."
fi

# --- Activar el tema y reconstruir el initramfs ---
sudo plymouth-set-default-theme -R quickshell
echo "[OK] Pantalla de carga instalada. Se verá en el próximo arranque."
