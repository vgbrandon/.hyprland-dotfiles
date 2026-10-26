# velure: generado desde el fondo de pantalla. No editar a mano.
# Colores del resaltado de fish (lo que se escribe, el completado, la selección) con los
# papeles de Velure, en color real (hex): sin los colores ANSI del tema por defecto de
# fish. Lo carga config.fish al abrir la terminal y otra vez cuando paleta avisa de un
# fondo nuevo (SIGUSR1, ver scripts/starship.sh).

# Lo que se escribe
set -g fish_color_normal '{{colors.p_text.default.hex}}'
set -g fish_color_command '{{colors.p_accent.default.hex}}'
set -g fish_color_keyword '{{colors.p_accent.default.hex}}'
set -g fish_color_param '{{colors.p_text.default.hex}}'
set -g fish_color_option '{{colors.p_text.default.hex}}'
set -g fish_color_quote '{{colors.p_accent2.default.hex}}'
set -g fish_color_operator '{{colors.p_accent3.default.hex}}'
set -g fish_color_redirection '{{colors.p_accent3.default.hex}}'
set -g fish_color_escape '{{colors.p_accent3.default.hex}}'
set -g fish_color_end '{{colors.p_accent3.default.hex}}'
set -g fish_color_error '{{colors.p_error.default.hex}}'
set -g fish_color_comment '{{colors.p_outline.default.hex}}'
set -g fish_color_autosuggestion '{{colors.p_outline.default.hex}}'
set -g fish_color_valid_path --underline
set -g fish_color_cancel '{{colors.p_error.default.hex}}'
set -g fish_color_history_current --bold

# Selección y coincidencias de la búsqueda: el tono en profundo, como lo seleccionado
# en Velure
set -g fish_color_selection '{{colors.p_onContainer.default.hex}}' --background='{{colors.p_container.default.hex}}'
set -g fish_color_search_match '{{colors.p_onContainer.default.hex}}' --background='{{colors.p_container.default.hex}}'

# Prompt de fish (sin Starship) y estado
set -g fish_color_cwd '{{colors.p_accent.default.hex}}'
set -g fish_color_cwd_root '{{colors.p_error.default.hex}}'
set -g fish_color_user '{{colors.p_subtext.default.hex}}'
set -g fish_color_host '{{colors.p_subtext.default.hex}}'
set -g fish_color_host_remote '{{colors.p_warning.default.hex}}'
set -g fish_color_status '{{colors.p_error.default.hex}}'

# Menú de completado (Tab)
set -g fish_pager_color_prefix '{{colors.p_accent.default.hex}}' --bold
set -g fish_pager_color_completion '{{colors.p_text.default.hex}}'
set -g fish_pager_color_description '{{colors.p_subtext.default.hex}}'
set -g fish_pager_color_progress '{{colors.p_onContainer.default.hex}}' --background='{{colors.p_container.default.hex}}'
set -g fish_pager_color_selected_background --background='{{colors.p_container.default.hex}}'
set -g fish_pager_color_selected_prefix '{{colors.p_onContainer.default.hex}}' --bold
set -g fish_pager_color_selected_completion '{{colors.p_onContainer.default.hex}}'
set -g fish_pager_color_selected_description '{{colors.p_onContainer.default.hex}}'
