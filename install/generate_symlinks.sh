#!/usr/bin/env bash

# ==============================================================================
# CONFIGURACIÓN INICIAL
# ==============================================================================
DOTFILES_DIR="$HOME/.hyprland-dotfiles"
HOME_DIR="$HOME"

conflicts=()

# ==============================================================================
# 1. OBTENER SOLO ARCHIVOS REALES DENTRO DE DOTFILES (NO CARPETAS)
# ==============================================================================
mapfile -t dotfiles_files < <(find "$DOTFILES_DIR" -type f | sed "s|$DOTFILES_DIR/||")

# ==============================================================================
# 2. EVALUAR CONFLICTOS REALES
# ==============================================================================
for relative_path in "${dotfiles_files[@]}"; do
    home_path="$HOME_DIR/$relative_path"

    # ---------------------------------------------------------
    # A) REVISAR SI ALGÚN PADRE EN HOME ES SYMLINK
    # ---------------------------------------------------------
    projected="$home_path"
    while [[ "$projected" != "$HOME_DIR" ]]; do
        projected=$(dirname "$projected")
        if [[ -L "$projected" ]]; then
            continue 2   # se descarta conflicto si un padre es symlink
        fi
    done

    # ---------------------------------------------------------
    # B) SI EXISTE EL ARCHIVO EN HOME Y NO ES SYMLINK → CONFLICTO
    # ---------------------------------------------------------
    if [[ -e "$home_path" && ! -L "$home_path" ]]; then
        conflicts+=("$home_path")
    fi
done

# ==============================================================================
# 3. MOSTRAR RESULTADOS
# ==============================================================================
if (( ${#conflicts[@]} == 0 )); then
    echo "No se detectaron conflictos."
else
    echo "Conflictos detectados:"
    printf "%s\n" "${conflicts[@]}"
fi

# ==============================================================================
# 4. MANEJO DE CONFLICTOS (BACKUP / DELETE / CANCEL)
# ==============================================================================

handle_conflicts() {
    local conflicts=("$@")

    if [ ${#conflicts[@]} -eq 0 ]; then
        return 0
    fi

    echo
    echo "Opciones:"
    echo "  1) Backear (renombrar *.bak)"
    echo "  2) Eliminar"
    echo "  3) Cancelar"
    read -rp "Elige opción: " choice

    case "$choice" in
        1) backup_conflicts "${conflicts[@]}"; return 0 ;;
        2) delete_conflicts "${conflicts[@]}"; return 0 ;;
        *)
            echo "Cancelado por el usuario. No se ejecutará stow."
            exit 1
            ;;
    esac
}

backup_conflicts() {
    local conflicts=("$@")
    declare -A dir_to_files

    # Agrupar por carpeta padre
    for f in "${conflicts[@]}"; do
        parent_dir=$(dirname "$f")
        dir_to_files["$parent_dir"]+="$f "
    done

    # Procesar cada grupo
    for dir in "${!dir_to_files[@]}"; do
        files=(${dir_to_files[$dir]})

        if can_backup_folder "$dir" "${files[@]}"; then
            echo "Backeando carpeta completa: $dir -> ${dir}.bak"
            mv "$dir" "${dir}.bak"
        else
            echo "Backeando archivos en $dir"
            for f in "${files[@]}"; do
                mv "$f" "${f}.bak"
            done
        fi
    done
}

can_backup_folder() {
    local target_dir="$1"; shift
    local conflict_files=("$@")

    # Obtener hijos reales de la carpeta en el HOME
    mapfile -t home_children < <(find "$target_dir" -maxdepth 1 -type f -printf "%f\n")

    # Directorio equivalente en DOTFILES
    df_relative="${target_dir/#$HOME\//}"
    df_dir="$DOTFILES_DIR/$df_relative"

    if [[ ! -d "$df_dir" ]]; then
        return 1
    fi

    # Hijos en DOTFILES
    mapfile -t df_children < <(find "$df_dir" -maxdepth 1 -type f -printf "%f\n")

    # Ordenar y comparar listas
    IFS=$'\n' sorted_home=($(sort <<< "${home_children[*]}"))
    IFS=$'\n' sorted_df=($(sort <<< "${df_children[*]}"))

    [[ "${sorted_home[*]}" == "${sorted_df[*]}" ]]
}

delete_conflicts() {
    for f in "$@"; do
        echo "Eliminando $f"
        rm -rf "$f"
    done
}

# Ejecutar manejo de conflictos
handle_conflicts "${conflicts[@]}"

# ==============================================================================
# 5. EJECUTAR STOW AUTOMÁTICAMENTE
# ==============================================================================
run_stow() {
    echo
    echo "Ejecutando stow . en $DOTFILES_DIR ..."
    (
        cd "$DOTFILES_DIR" || {
            echo "No se pudo acceder a $DOTFILES_DIR"
            exit 1
        }
        stow .
    )
    echo "Stow completado."
}

cd "$DOTFILES_DIR"
run_stow
