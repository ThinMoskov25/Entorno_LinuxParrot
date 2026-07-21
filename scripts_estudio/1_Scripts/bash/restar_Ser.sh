#!/bin/bash

# Colores para mensajes
verde="\033[1;32m"
rojo="\033[1;31m"
azul="\033[1;34m"
cian="\033[1;36m"
reset="\033[0m"

# Función para restaurar servicios de red y modo managed
function restaurar_procesos() {
    echo -e "${azul}[*] Detectando interfaces disponibles...${reset}"

    # Obtener interfaces
    mapfile -t interfaces < <(iw dev | awk '$1=="Interface"{print $2}')

    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${rojo}[!] No se detectaron interfaces inalámbricas.${reset}"
        exit 1
    fi

    echo -e "${verde}Interfaces detectadas:${reset}"
    for i in "${!interfaces[@]}"; do
        echo -e "  ${cian}$((i + 1))${reset}) ${interfaces[$i]}"
    done

    echo -e "${verde}Selecciona el número de tu interfaz (presiona Enter para usar la primera):${reset}"
    read -rp " #> " opcion

    # Si no hay entrada, usar la primera
    if [[ -z "$opcion" ]]; then
        antena="${interfaces[0]}"
    elif [[ "$opcion" =~ ^[0-9]+$ ]] && (( opcion >= 1 && opcion <= ${#interfaces[@]} )); then
        antena="${interfaces[$((opcion - 1))]}"
    else
        echo -e "${rojo}[!] Opción inválida.${reset}"
        exit 1
    fi

    echo -e "${cian}[+] Interfaz seleccionada: $antena${reset}"

    # Verificar que la interfaz existe
    if ! ip link show "$antena" &>/dev/null; then
        echo -e "${rojo}[!] La interfaz '$antena' no existe. Revisa el nombre.${reset}"
        exit 1
    fi

    echo -e "${verde}[+] Restaurando servicios de red...${reset}"

    # Reiniciar NetworkManager
    if sudo systemctl restart NetworkManager; then
        echo -e "${verde}[✔] NetworkManager reiniciado.${reset}"
    else
        echo -e "${rojo}[✘] Error al reiniciar NetworkManager.${reset}"
    fi

    # Iniciar wpa_supplicant
    if sudo systemctl start wpa_supplicant 2>/dev/null || sudo service wpa_supplicant start 2>/dev/null; then
        echo -e "${verde}[✔] wpa_supplicant iniciado.${reset}"
    else
        echo -e "${rojo}[✘] No se pudo iniciar wpa_supplicant.${reset}"
    fi

    # Restaurar interfaz a modo managed
    sudo ip link set "$antena" down
    if sudo iw dev "$antena" set type managed; then
        sudo ip link set "$antena" up
        echo -e "${verde}[✔] Interfaz '$antena' restaurada a modo 'managed'.${reset}"
    else
        echo -e "${rojo}[✘] No se pudo cambiar el tipo de la interfaz.${reset}"
    fi

    # Confirmar modo actual
    modo_actual=$(iw dev "$antena" info | grep type | awk '{print $2}')
    if [[ "$modo_actual" == "managed" ]]; then
        echo -e "${verde}[✔] Modo confirmado: managed.${reset}"
    else
        echo -e "${rojo}[✘] La interfaz sigue en modo: $modo_actual${reset}"
    fi

    echo -e "${verde}[+] Restauración completada.${reset}"
}

# Ejecutar función automáticamente
restaurar_procesos
