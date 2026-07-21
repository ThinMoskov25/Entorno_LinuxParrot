#!/bin/bash
# =============================================================================
# Ramdom_password.sh - Generador de contrasenas aleatorias seguras
# Autor: Moskov
# Descripcion: Genera contrasenas con control de longitud, complejidad
#              y opcion de copiar al clipboard.
# =============================================================================

# Colores
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Generar contrasena con caracteres mixtos (incluye especiales)
generate_password() {
    local length="$1"
    local include_special="$2"
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    if [[ "$include_special" == "s" ]]; then
        chars="${chars}!@#\$%&*_+-="
    fi

    # Usar /dev/urandom para mayor aleatoriedad
    local password=""
    password=$(tr -dc "$chars" < /dev/urandom | head -c "$length")
    echo "$password"
}

# Menu principal
main() {
    echo -e "\n${GREEN}  ================================${RESET}"
    echo -e "${GREEN}   Generador de Contrasenas${RESET}"
    echo -e "${GREEN}  ================================${RESET}\n"

    # Longitud
    while true; do
        read -rp "  Longitud de la contrasena (8-64): " length
        if [[ "$length" =~ ^[0-9]+$ ]] && (( length >= 8 && length <= 64 )); then
            break
        fi
        echo -e "${RED}  [!] Ingresa un numero entre 8 y 64.${RESET}"
    done

    # Caracteres especiales
    read -rp "  Incluir caracteres especiales? (s/n): " include_special

    # Cantidad
    read -rp "  Cuantas contrasenas generar? [1]: " cantidad
    cantidad=${cantidad:-1}

    echo -e "\n${CYAN}  Contrasenas generadas:${RESET}"
    echo -e "  ──────────────────────────────"

    for ((i=1; i<=cantidad; i++)); do
        pass=$(generate_password "$length" "$include_special")
        echo -e "  ${GREEN}${i}.${RESET} $pass"
    done

    echo -e "  ──────────────────────────────"

    # Copiar la ultima al clipboard si xclip existe
    if command -v xclip &>/dev/null && [[ "$cantidad" -eq 1 ]]; then
        echo -n "$pass" | xclip -sel clip
        echo -e "\n${YELLOW}  [+] Copiada al clipboard.${RESET}"
    fi

    echo ""
}

main
