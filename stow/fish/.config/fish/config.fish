if status is-interactive
    # Eliminando mensaje de saludo de Fish
    function fish_greeting; end

    # eza (better 'ls')
    if type -q eza
        alias l="eza --icons"
        alias ls="eza --icons"
        alias ll="eza -lg --icons"
        alias la="eza -lag --icons"
        alias lt="eza -lTg --icons"
        alias lt1="eza -lTg --level=1 --icons"
        alias lt2="eza -lTg --level=2 --icons"
        alias lt3="eza -lTg --level=3 --icons"
        alias lta="eza -lTag --icons"
        alias lta1="eza -lTag --level=1 --icons"
        alias lta2="eza -lTag --level=2 --icons"
        alias lta3="eza -lTag --level=3 --icons"
    end

    # pnpm
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    fish_add_path -m "$PNPM_HOME"
    # pnpm end

    # Asegurar binarios locales
    fish_add_path -m "$HOME/.local/bin"

    if type -q zoxide
        zoxide init fish | source
    end

    # opencode
    fish_add_path -m "$HOME/.opencode/bin"

    # Esto siempre debe ir al final
    if type -q starship
        set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
        starship init fish | source
    end
end

# DeepSeek API Key para Zed
# Reemplazar por tu key real
set -gx DEEPSEEK_API_KEY "AQUI_TU_KEY"

# opencode
fish_add_path /home/vgbrandon/.opencode/bin
