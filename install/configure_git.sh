#!/bin/bash

echo "========================================"
echo "   Configuración opcional de Git"
echo "========================================"
echo ""
read -p "¿Deseas configurar Git ahora? (s/n) [s]: " respuesta

# Si la respuesta está vacía, usar "s" como defecto
respuesta=${respuesta:-s}

case "$respuesta" in
    s|S|si|SI|Sí|sí)
        echo ""
        echo "Configurando Git..."
        read -p "Ingresa tu nombre de usuario de Git: " git_user
        read -p "Ingresa tu correo electrónico de Git: " git_email

        if [[ -z "$git_user" || -z "$git_email" ]]; then
            echo "Error: usuario o correo vacío. Cancelando configuración."
            exit 1
        fi

        git config --global user.name "$git_user"
        git config --global user.email "$git_email"

        echo ""
        echo "Git configurado correctamente:"
        echo "Nombre de usuario: $(git config --global user.name)"
        echo "Correo electrónico: $(git config --global user.email)"
        ;;
    n|N|no|NO)
        echo "Saltando configuración de Git."
        ;;
    *)
        echo "Opción no válida. Por favor ejecuta el script de nuevo."
        exit 1
        ;;
esac

echo ""
echo "Script finalizado."

