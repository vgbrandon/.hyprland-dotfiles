# Hyprland Dotfiles

Configuración modular para Arch Linux + Hyprland con instalación automatizada y arquitectura escalable.

---

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/vgbrandon/.hyprland-dotfiles/main/install.sh | bash
```

---

## Arquitectura

Este proyecto usa una arquitectura modular basada en tareas.

```txt
run.sh      → orquesta la ejecución
tasks/      → define el flujo (qué hacer)
services/   → implementa la lógica (cómo hacerlo)
packages/   → contiene datos (listas de paquetes)
shared/     → utilidades comunes
stow/       → configuraciones (futuro)
```

El flujo de instalación se divide en tareas ordenadas, mientras que la lógica reutilizable se mantiene en services.
Las listas de paquetes se tratan como datos y las utilidades se centralizan en shared.

---

## Características

* Instalación automática de paquetes (pacman)
* Soporte AUR con bootstrap automático de yay
* Arquitectura modular y mantenible
* Separación clara entre lógica, datos y flujo
* Aplicación de dotfiles (pendiente)
* Configuración de entorno (pendiente)

---

## Estructura

```txt
.hyprland-dotfiles/
├── install.sh
├── README.md
│
├── setup/
│   ├── env.sh
│   ├── run.sh
│   │
│   ├── tasks/
│   │   ├── 00-checks.sh
│   │   ├── 01-packages.sh
│   │   ├── 02-stow.sh
│   │   └── 03-post.sh
│   │
│   ├── services/
│   │   ├── pacman.sh
│   │   ├── aur.sh
│   │   └── stow.sh
│   │
│   ├── packages/
│   │   ├── base.txt
│   │   ├── pacman.txt
│   │   └── aur.txt
│   │
│   └── shared/
│       └── utils.sh
│
├── stow/
├── scripts/
├── assets/
└── docs/
```

---

## Flujo de ejecución

```txt
curl | bash
   ↓
install.sh
   ↓
clona en ~/.hyprland-dotfiles
   ↓
run.sh
   ↓
tasks/*
```

---

## Estado actual

| Módulo     | Estado    |
| ---------- | --------- |
| Instalador | listo     |
| Pacman     | listo     |
| AUR (yay)  | listo     |
| Stow       | pendiente |
| Configs WM | pendiente |

---

## Gestión de paquetes

Ubicación:

```txt
setup/packages/
```

Formato:

```txt
paquete                  # descripción
```

Ejemplo:

```txt
thunar                   # gestor de archivos
neovim                   # editor de texto
wl-gammarelay            # control de brillo en Wayland
```

Tipos:

* base.txt → dependencias mínimas
* pacman.txt → repos oficiales
* aur.txt → AUR

---

## Tasks

Orden de ejecución:

```txt
00 → validaciones
01 → paquetes
02 → stow (pendiente)
03 → post (pendiente)
```

---

## Services

Encapsulan interacción con herramientas externas:

```txt
pacman.sh → instalación con pacman
aur.sh    → instalación AUR con yay
stow.sh   → aplicación de dotfiles
```

---

## Convención de commits

Formato:

```txt
tipo(scope): mensaje
```

Ejemplo:

```bash
feat(tasks): agregar instalación de paquetes
fix(services): corregir instalación AUR
```

Tipos:

* feat → nueva funcionalidad
* fix → corrección
* refactor → mejora interna
* chore → mantenimiento
* docs → documentación

---

## Roadmap

* Implementar GNU Stow con backup automático
* Soporte para flags (--skip, --only)
* Logs persistentes
* Perfiles (minimal, desktop, laptop)
* Configuración completa de Hyprland
* Waybar + widgets

---

## Requisitos

* Arch Linux
* conexión a internet
* permisos sudo
