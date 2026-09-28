# Hyprland Dotfiles

Configuración modular para Arch Linux + Hyprland, gestionada con [chezmoi](https://www.chezmoi.io/).

---

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/vgbrandon/.hyprland-dotfiles/main/install.sh | bash
```

`chezmoi init` va a pedir tu nombre y email de git, si quieres habilitar AUR, y tu DeepSeek API key (opcional, Enter para omitir) — esos datos quedan guardados localmente en `~/.config/chezmoi/chezmoi.toml`, nunca en el repo.

---

## Uso

Comandos del día a día una vez instalado:

Ver qué cambiaría en tu `$HOME` antes de tocar nada:

```bash
chezmoi diff
```

Aplicar esos cambios de verdad:

```bash
chezmoi apply
```

Editar un dotfile (abre el archivo fuente del repo, no el de destino):

```bash
chezmoi edit --apply ~/.config/fish/config.fish
```

Si editaste el archivo de destino directamente en vez de con `edit`, traer ese cambio de vuelta al repo:

```bash
chezmoi re-add ~/.config/fish/config.fish
```

Agregar un dotfile nuevo que no está gestionado todavía:

```bash
chezmoi add ~/.config/algo/nuevo.conf
```

Traer cambios nuevos del repo (`git pull`) y aplicarlos:

```bash
chezmoi update
```

Abrir una shell en el directorio fuente del repo (para commitear/pushear):

```bash
chezmoi cd
```

Los scripts en `.chezmoiscripts/` (`checks/`, `packages/`, `post/`) no se vuelven a correr solos si no cambia su contenido — es la idea de `run_once_`/`run_onchange_`. Si necesitas forzar que se re-ejecuten todos (por ejemplo, para probar un cambio sin alterar el archivo):

```bash
chezmoi state delete-bucket --bucket=scriptState
```

```bash
chezmoi apply
```

---

## Arquitectura

El repo tiene dos partes claramente separadas:

```txt
.hyprland-dotfiles/
├── .chezmoiroot        → le dice a chezmoi que la raíz real es "home/"
├── install.sh          → bootstrap: instala chezmoi y aplica el repo
├── assets/             → binarios que NO son dotfiles
├── docs/               → documentación adicional
├── scripts/            → scripts sueltos de mantenimiento, fuera de chezmoi
│
└── home/               → todo lo que chezmoi gestiona vive aquí
    ├── .chezmoi.toml.tmpl      → prompts (nombre, email, enableAur, api key)
    ├── .chezmoidata/           → datos que consumen los templates y scripts
    │   └── packages.yaml       → paquetes como datos
    ├── .chezmoiscripts/        → scripts run_once_/run_onchange_, uno por responsabilidad
    │   ├── checks/             → validaciones previas
    │   ├── packages/           → instalación de paquetes
    │   └── post/               → un script por responsabilidad (thunar, fish, opencode, refind, engrammer)
    ├── dot_config/             → equivalente directo de ~/.config
    └── dot_gitconfig.tmpl      → usa {{ .name }} / {{ .email }}
```

Todo lo que está fuera de `home/` (README, `assets/`, `docs/`, `scripts/`) es invisible para chezmoi: no se aplica, no se toca. Solo existe para documentación y binarios auxiliares.

---

## Gestión de paquetes

Ubicación: `home/.chezmoidata/packages.yaml`, con tres listas (`base`, `pacman`, `aur`) consumidas por `.chezmoiscripts/packages/run_onchange_install-packages.sh.tmpl`.

AUR está deshabilitado por defecto (`enableAur: false` en el prompt de `chezmoi init`) tras un incidente de seguridad previo. Para habilitarlo:

```bash
chezmoi init --data enableAur=true
```

o editando directamente `~/.config/chezmoi/chezmoi.toml`.

---

## DeepSeek API key

`DEEPSEEK_API_KEY` (usada por Zed/Fish) se pide como un prompt más de `chezmoi init`, igual que el nombre y el email de git. Queda guardada localmente en `~/.config/chezmoi/chezmoi.toml` (nunca en el repo) y `config.fish.tmpl` la vuelca al entorno solo si la completaste — si la dejas vacía, simplemente no se define.

Para cambiarla más adelante:

```bash
chezmoi init --data deepseekApiKey=tu-nueva-key
```

o editando directamente `~/.config/chezmoi/chezmoi.toml`.

**Nota**: como con el nombre/email, este valor no viaja automáticamente a una máquina nueva — hay que volver a escribirlo (o completarlo vacío) la primera vez que corres `chezmoi init` ahí.

---

## Convención de commits

Formato:

```txt
tipo(scope): mensaje
```

Ejemplo:

```bash
feat(scripts): agregar instalación de paquetes
fix(post): corregir configuración de fish
```

Tipos: `feat`, `fix`, `refactor`, `chore`, `docs`.

---

## Convención de descripción de PR

Formato recomendado:

```txt
Se <acción principal>.

Antes:
<contexto del problema o comportamiento previo>

Ahora:
<cambios aplicados y resultado esperado>
```

Notas:

- Escribir en español, claro y directo.
- Explicar primero el problema funcional (Antes) y luego la solución (Ahora).
- Mencionar archivos clave modificados cuando aporten contexto.
- Cerrar indicando el impacto visible para el usuario o entorno.

---

## Requisitos

Este repo asume una base ya instalada — no instala el sistema operativo, el compositor ni el bootloader por ti. El flujo pensado es instalar Arch con [`archinstall`](https://wiki.archlinux.org/title/Archinstall), eligiendo ahí:

- Perfil de escritorio **Hyprland**
- Bootloader **rEFInd** (opcional — si eliges otro bootloader, el resto de la instalación funciona igual, solo se saltea el tema visual de rEFInd; ver `checks/03-refind` y `post/refind-theme`)

Y además:

- conexión a internet
- permisos sudo
