# Prisma

El sistema de diseño de la shell. Se llama así porque, como un prisma, es vidrio que
toma sus colores de la luz que recibe: aquí, del fondo de pantalla.

Junta lo funcional de **Material You**, el acabado de **macOS** y el material de
**Windows 11**. Los colores salen siempre de **matugen** (del fondo de pantalla), así
que todo cambia con el fondo.

Las rutas son relativas a `~/.config/quickshell/` (en este repo,
`home/dot_config/quickshell/`); las del greeter, a `~/.config/quickshell-greeter/`.

- Tokens: `services/Design.qml`
- Componentes: `components/design/`
- Guía de estilo (todos los tokens y componentes con ejemplos que se pueden usar):
  `quickshell ipc call styleguide toggle` (`modules/styleguide/`)
- Toda la shell lo usa: la barra (`modules/bar/`), los paneles, las ventanas y las
  pantallas de bloqueo e inicio de sesión. Ver [Cómo se aplica](#cómo-se-aplica-al-resto-de-la-shell).

## Principios

1. **Color tonal.** Las superficies no son grises neutros: llevan un poco del tono
   del fondo. Lo activo y lo seleccionado usa **contenedores tonales** (relleno suave
   con el texto en el tono fuerte). El **acento sólido** solo para lo más importante
   (la acción principal, un interruptor encendido, el progreso).
2. **Dos materiales.** **Mica** para la barra y los fondos grandes: poco
   transparente, sobria, se lee con cualquier cosa detrás. **Vidrio esmerilado**
   para lo que flota (paneles, menús, avisos): más translúcido y con sombra.
3. **Detalles finos.** Borde de 1 px semitransparente con un brillo más claro arriba
   (el canto del vidrio), sombras amplias y suaves solo en lo que flota, tipografía
   nítida con una escala fija y cifras tabulares en los números.
4. **Forma moderada.** Radios de 8 en los elementos y 12 en los paneles; nada de
   píldoras por todas partes.
5. **Movimiento sutil.** Rápido, con curvas suaves y sin rebotes.

## Tokens (`Design.*`)

### Color

| Token | Rol de matugen | Uso |
| --- | --- | --- |
| `background` | `surface_dim` | Lo más bajo; tinte de la Mica y del vidrio |
| `surface0` | `surface_container_low` | Campos de texto (hundidos) |
| `surface1` | `surface_container` | Tarjetas (contrastan sobre el vidrio) |
| `surface2` | `surface_container_high` | Mosaicos, segmentado, elementos sobre tarjetas |
| `surface3` | `surface_container_highest` | Pistas de interruptores y deslizadores |
| `onSurface` / `onSurfaceVariant` / `muted` | `on_surface` / `on_surface_variant` | Texto principal / secundario / apagado |
| `accent` / `onAccent` | `primary` / `on_primary` | Acción principal, encendido, progreso |
| `accentContainer` / `onAccentContainer` | `primary_container` | Mosaicos encendidos, avatar |
| `tonal` / `onTonal` | `secondary_container` | Lo activo y lo seleccionado |
| `outline` / `outlineVariant` | `outline` / `outline_variant` | Bordes de casillas y campos / separadores |
| `error`, `success`, `warning`, `info` | `error`, `green`, `yellow`, `blue` | Estados (armonizados con el fondo) |
| `hoverLayer` / `pressLayer` | `on_surface` al 8 % / 12 % | Capa de estado encima de cualquier color |
| `border` / `borderHighlight` | `on_surface` al 10 % / 20 % | Borde de 1 px y brillo del canto |

### Materiales

| Material | Tinte | Opacidad | Dónde |
| --- | --- | --- | --- |
| Mica | `micaTint` (`background`) | `micaOpacity` 0.86 | Barra, fondos grandes |
| Vidrio | `glassTint` (`background`) | `glassOpacity` 0.68 | Paneles, menús, notificaciones, avisos |
| Sólido | `surface1` | 1 | Contenido, tarjetas dentro de un panel |

Las opacidades solo se aplican con **Ajustes → Barra y paneles translúcidos**
encendido; apagado, todos los materiales son opacos (`micaOpacity` y `glassOpacity`
valen 1).

El desenfoque de verdad lo hace Hyprland: la regla de capa de `hyprland.lua` desenfoca
los namespaces `quickshell:(bar|config-panel|notification-center|ai|osd)`. Una ventana
nueva con material transparente necesita su namespace en esa regla.

### Tipografía

Fuente `Adwaita Sans` (basada en Inter); `JetBrainsMono Nerd Font` para lo monoespaciado.
Los iconos siguen siendo los de Nerd Font (`Theme.i*`). Los que no trae (como el logo de
Bitwarden) están en una fuente propia, **Prisma Icons** (`assets/fonts/PrismaIcons.otf`),
para que se vean igual de nítidos: se dibujan como letras, no como imágenes. Para añadir
uno: su SVG en `assets/icons/<nombre>.svg` (caja de 24×24), su código en
`assets/icons/iconos.json` (área privada `U+100000…`), `scripts/build-icons.py` (ver su
cabecera) y `Theme.i<Nombre>`. `Icon` usa esa fuente sola para esos códigos.

| Estilo | Tamaño | Peso | Uso |
| --- | --- | --- | --- |
| `display` | 34 | ligera | Saludos, números grandes |
| `title` | 22 | media | Títulos de ventanas y secciones |
| `headline` | 16 | seminegrita | Encabezados dentro de un panel |
| `body` | 13 | normal | Texto normal |
| `label` | 12 | media | Botones, pestañas, la barra |
| `caption` | 11 | normal | Subtítulos, horas, detalles |

Números que cambian (hora, porcentajes, contadores): `font.features: { "tnum": 1 }`.

### Forma, espacio, elevación y movimiento

- Radios: `radiusXs` 4 (casillas), `radiusSm` 8 (botones, filas), `radiusMd` 12
  (paneles, mosaicos), `radiusLg` 16.
- Espacios: múltiplos de 4 (`Design.space`: 0, 4, 8, 12, 16, 20, 24, 32).
- Elevación (`Design.elevation[0..3]`): 0 en lo que va pegado (barra), 1 en tarjetas,
  2 en paneles y avisos, 3 en lo más alto (centro de control).
- Movimiento: `fast` 120 ms (capas de estado), `normal` 200 ms (cambios de estado,
  deslizamientos), `slow` 320 ms; curva `easing` (OutCubic).

## Componentes (`import qs.components.design`)

| Componente | Para qué | Ejemplo |
| --- | --- | --- |
| `Txt` | Texto con un estilo de la escala | `Txt { text: "Hola"; textStyle: Design.headline }` |
| `Surface` | Fondo con material, borde, brillo y sombra; con `backdrop` desenfoca esa imagen detrás (vidrio esmerilado de verdad) | `Surface { material: "glass"; elevation: 2 }` |
| `GlassEdge` | El brillo del canto superior del vidrio (dentro de un fondo) | `GlassEdge { inset: radius }` |
| `Btn` | Botón con texto: `filled`, `tonal`, `outline`, `text` | `Btn { kind: "filled"; text: "Conectar" }` |
| `IconBtn` | Botón de icono: `plain`, `tonal`, `filled`; `checked` = activo | `IconBtn { icon: Theme.iBell; checked: true }` |
| `Toggle` | Interruptor | `Toggle { checked: true; onToggled: … }` |
| `Slide` | Deslizador | `Slide { value: 0.4; onMoved: v => … }` |
| `Segmented` | Control segmentado | `Segmented { options: ["Día", "Mes"] }` |
| `Check` | Casilla con texto | `Check { text: "Recordar" }` |
| `Field` | Campo de texto (al enfocarlo, el borde en acento, sin halo); `big: true` es el buscador grande de las ventanas (lanzador, portapapeles, atajos, Bitwarden). `focusInput()` le da el foco y `keyPressed(e)` deja manejar teclas (flechas, Enter…) | `Field { icon: Theme.iSearch; placeholder: "Buscar" }` |
| `ListRow` | Fila de lista; `selected` = tonal | `ListRow { icon: …; title: …; subtitle: … }` |
| `Tile` | Mosaico de ajuste rápido | `Tile { icon: Theme.iWifi; title: "Wi-Fi"; checked: true }` |
| `NumberStep` | Ajuste numérico: nombre y − valor + | `NumberStep { label: "Enfoque"; value: 25; unit: "min"; onChanged: v => … }` |
| `ToggleRow` | Fila con texto e interruptor | `ToggleRow { text: "Sonido"; checked: …; onToggled: … }` |

Reglas al usarlos:

- Colores, tamaños, radios y tiempos siempre desde `Design`, nunca a mano.
- Todo lo que se pulsa lleva capa de estado (`hoverLayer` / `pressLayer`) y cursor de mano.
- Lo activo, tonal; el acento sólido, solo para lo principal.
- `Toggle` y `Segmented` cambian solos al pulsarlos; con `follow: false` solo avisan
  y el estado lo decide quien los usa (lo normal al reflejar un servicio).
- Los paneles (`BarPopup`, `SidePanel`, `OverlayWindow`) ya son de vidrio: lo de
  dentro solo usa tokens y componentes.
- `Surface` con `backdrop` (una imagen) desenfoca la parte de esa imagen que tiene
  detrás: lo usan la guía y las pantallas de bloqueo e inicio de sesión. Si la
  superficie se mueve dentro de otra cosa, pásale algo que cambie con ese movimiento en
  `scrollY` (p. ej. `card.x + card.y`) para que se recoloque. En el escritorio se deja
  `backdrop` vacío y desenfoca Hyprland.

## La guía de estilo

`quickshell ipc call styleguide toggle` abre una ventana flotante con todo: paleta,
materiales, tipografía, forma, botones, controles y ejemplos completos (lista, ajustes
rápidos, notificación, aviso de volumen) bajo una barra de ejemplo. Es el sitio para
probar cambios del diseño antes de aplicarlos: al tocar `Design.qml` o un componente,
la guía se actualiza. `quickshell ipc call styleguide scrollTo <y>` la desplaza (para
capturas).

## Cómo se aplica al resto de la shell

El diseño llega a casi todo a través de los componentes compartidos, que ya usan los
tokens de `Design` con la API de siempre:

- Contenedores: `BarPopup` (paneles de la barra, todos de `Design.popupWidth` = 360 px
  de ancho; los menús, como el de la bandeja, son más estrechos), `SidePanel` (ajustes,
  notificaciones, IA; 400 px) y `OverlayWindow` (lanzador, portapapeles, energía, atajos,
  pantallas, teclado, perfil…) son de vidrio con borde de 1 px y `GlassEdge` (el brillo
  del canto). `OverlayWindow` va casi opaco: Hyprland no desenfoca esas capas.
- `PanelHeader`, `Section`, `Card`, `Chip`/`Chips`, `TextButton` (como `Btn`),
  `Switch` (es el `Toggle`), `SwitchRow`, `Slider` (con bola si es interactivo)
  y `Cycler`.
- `Theme.font` es la fuente del diseño (Adwaita Sans) y `Theme.radiusSmall` el radio de
  los elementos (8). Los colores de `Theme` son los mismos roles de matugen que los de
  `Design`, así que lo que aún los usa encaja.

## La barra (`modules/bar/`)

- De Mica, pegada a un borde de lado a lado (Ajustes → Barra: arriba, abajo o un
  lateral), con los elementos sueltos sobre ella: nada de píldoras.
- Escritorios con número (`Workspaces.qml`): el activo en un contenedor tonal más
  largo que se desliza; con ventanas, más claros; vacíos, apagados.
- Todo lo que se pulsa tiene la capa de hover: los botones son `IconBtn` y lo demás
  (pomodoro, grabación, título de lo que suena) va en `HoverBox.qml`.
- En los laterales va en columna: horas sobre minutos, volumen con el número debajo,
  sin títulos ni CPU/RAM. En un monitor bajo (menos de 900 px), modo compacto: botones
  de 24 px, 6 escritorios a la vista y sin el botón de reproducción.
- En un monitor estrecho (menos de 1600 px de ancho) no muestra el título de la ventana.

## Pantallas de bloqueo e inicio de sesión

`modules/lock/LockContent.qml` y `quickshell-greeter/GreeterContent.qml` comparten
diseño: reloj grande a la izquierda (horas sobre minutos, juntos) y tarjeta de la
contraseña a la derecha, como un bloque centrado (el ancho de los dos más ~260 px), y
una mini barra abajo (reproductor o sesión, y energía).

- El fondo se ve **nítido**, con un velo suave más denso bajo el reloj.
- La tarjeta, la cápsula de la fecha y los bloques de la mini barra son **vidrio
  esmerilado de verdad**: `Surface` con `backdrop: wallpaper` desenfoca solo lo que
  tienen detrás. Tinte: 0.78 en la tarjeta y la fecha, 0.6 en la mini barra (que
  suele caer sobre zonas más oscuras). No dependen de la opción de translucidez.
- El greeter copia al instalarse `Design.qml`, `IconBtn`, `GlassEdge` y `Surface`
  (`quickshell-greeter/install.sh`); el script de chezmoi se vuelve a ejecutar
  cuando cambian.

**Probarlas sin bloquear:** copiar `~/.config/quickshell` a `/tmp`, y en la copia
hacer que `Theme` lea el `theme.json` real y no ejecute matugen ni escriba para el
greeter (`setWallpaper` y `shareWithGreeter` sin efecto) y que `Wallpaper` no elija
fondo al arrancar. Después, un `shell.qml` con un `FloatingWindow` que muestre
`LockContent` y ejecutarlo con `quickshell -p /tmp/…/shell.qml`. Para el greeter,
lo mismo con su estructura de `/etc/greetd/quickshell`.

## Estado

| Parte | Diseño |
| --- | --- |
| Barra | Prisma, en cualquier borde (Ajustes → Barra). En los laterales va en columna, sin títulos ni CPU/RAM, y en monitores bajos en modo compacto. La barra clásica de píldoras se retiró |
| Paneles de la barra, ajustes, notificaciones, IA, lanzador, portapapeles, energía, atajos, pantallas, teclado, perfil, fondos | Prisma |
| Notificaciones emergentes y aviso de volumen/brillo | Prisma |
| Selector de fondos | Prisma, en dos formas a elegir en Ajustes → Selector de fondos: **carrusel** (el señalado grande en el centro y los vecinos más pequeños; `WallpaperCarousel.qml`) o **cuadrícula** a pantalla completa con buscador (`WallpaperGrid.qml`). Comparten `WallpaperThumb.qml` y `PickerLayer.qml` (la capa que oscurece el escritorio) |
| Lanzador | Prisma, como paleta de comandos (`modules/launcher/LauncherWindow.qml`): apps y acciones de la shell en una lista agrupada; las acciones muestran su atajo de `hyprland.lua` (por la descripción del bind). Las acciones están en `services/Launcher.qml` (`actions`) |
| Sonido | Prisma (`modules/audio/`): panel junto al volumen de la barra con salida, entrada y apps; lógica en `services/Audio.qml` |
| Notas | Prisma (`modules/notes/NotesWindow.qml`): lista con buscador y editor de texto simple; las notas son .txt en `~/Notas` (`services/Notes.qml`) |
| Reloj del escritorio | Prisma, apilado como el de la pantalla de bloqueo (`modules/wallpaper/DesktopClock.qml`) |
| Pantalla de bloqueo y de inicio de sesión | Prisma (ver su sección) |
