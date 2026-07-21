#!/bin/bash
# Script para TP-Link TL-WN722N en modo monitor - Versión final
# Original: Dkm Rpg - Modificado por ChatGPT

# Colores
blanco="\033[1;37m"
magenta="\033[0;35m"
rojo="\033[1;31m"
verde="\033[1;32m"
amarillo="\033[1;33m"
azul="\033[1;34m"

# Mostrar banner si existe
function show_banner() {
    if [[ -f "banner.py" ]]; then
        python3 banner.py
    else
        echo -e "$amarillo[!] banner.py no encontrado. Continuando...\n"
    fi
}

# Menú principal
function menu() {
    clear
    show_banner
    echo -e " ${verde}1)${blanco} Compilar kernel (Primera vez)"
    echo -e " ${verde}2)${blanco} Colocar en modo monitor (Después de compilar)"
    echo -e " ${verde}3)${blanco} Restaurar procesos de red"
    echo -e " ${verde}4)${blanco} Salir"
    echo -n " #> "
    read opcion

    case "$opcion" in
        1) compilar_driver ;;
        2) activar_monitor ;;
        3) restaurar_procesos ;;
        4) salir ;;
        *) 
            echo -e "$rojo [!] Opción no válida"
            sleep 1
            menu
        ;;
    esac
}

# Compilar driver rtl8188eus
function compilar_driver() {
    clear
    echo -e "$verde[+] Compilando el driver, esto puede tardar un poco..."

    sudo rmmod r8188eu.ko 2>/dev/null
    cd rtl8188eus || { echo -e "$rojo[!] No se encontró la carpeta rtl8188eus"; exit 1; }

    echo "blacklist r8188eu.ko" | sudo tee /etc/modprobe.d/realtek.conf > /dev/null

    echo -e "$azul[*] Compilando..."
    make
    sudo make install
    sudo modprobe 8188eu

    cd ..
    echo -e "$verde[+] Compilación e instalación completadas."
    sleep 2
    menu
}

# Activar modo monitor
function activar_monitor() {
    sudo airmon-ng
    echo -e "$verde Ingresa el nombre de tu interfaz (ej: wlan0):"
    read -rp " #> " antena
    export antena

    echo -e "$blanco ¿Estás seguro que '$amarillo$antena$blanco' es correcto? (s/n)"
    read -rp " #> " confirmacion
    if [[ "$confirmacion" == "s" || "$confirmacion" == "S" ]]; then
        iniciar_monitor
    else
        activar_monitor
    fi
}

# Iniciar modo monitor con captura e informe
function iniciar_monitor() {
    clear
    sudo rmmod r8188eu.ko 2>/dev/null
    sudo modprobe 8188eu

    echo -e "$rojo[!] Desconecta y vuelve a conectar la antena. Presiona ENTER para continuar..."
    read

    echo -e "$rojo[*] Matando procesos que interfieren..."
    sudo airmon-ng check kill

    sudo ifconfig "$antena" down
    sudo iw dev "$antena" set type monitor
    sudo ifconfig "$antena" up

    timestamp=$(date +%Y%m%d_%H%M%S)
    output_base="captura_$timestamp"

    echo -e "$verde[+] Escaneando redes... Presiona CTRL+C para detener y generar informe"

    # Al presionar CTRL+C, ejecutar generar_informe
    trap 'generar_informe "$output_base"' SIGINT

    sudo airodump-ng "$antena" --write "$output_base" --output-format csv
}

# Generar informe con columnas ordenadas como airodump-ng
function generar_informe() {
    cancel_time=$(date +%H-%M-%S)
    archivo_csv="$1-01.csv"
    informe_txt="redes_${cancel_time}.txt"

    echo -e "\n$verde[+] Generando informe: $informe_txt"

    if [[ -f "$archivo_csv" && -s "$archivo_csv" ]]; then
        echo "INFORME DE REDES DETECTADAS - $(date)" > "$informe_txt"
        echo "--------------------------------------------------------------------------------------------" >> "$informe_txt"
        printf "%-20s %-4s %-7s %-6s %-4s %-3s %-5s %-6s %-8s %-6s %-s\n" \
            "BSSID" "PWR" "Beacons" "#Data" "#/s" "CH" "MB" "ENC" "CIPHER" "AUTH" "ESSID" >> "$informe_txt"
        echo "--------------------------------------------------------------------------------------------" >> "$informe_txt"

        awk -F',' '
        BEGIN { OFS=" " }
        /^[ \t]*$/ { exit }
        NR > 2 && $14 !~ /<length: 0>/ && $14 !~ /^ *$/ {
            gsub(/^[ \t]+|[ \t]+$/, "", $1)
            printf "%-20s %-4s %-7s %-6s %-4s %-3s %-5s %-6s %-8s %-6s %-s\n", \
                $1, $9, $10, $11, $12, $4, $5, $6, $7, $8, $14
        }
        ' "$archivo_csv" >> "$informe_txt"

        echo -e "$verde[+] Informe generado en: $informe_txt"
    else
        echo -e "$rojo[!] No se encontró o está vacío el archivo CSV: $archivo_csv"
    fi

    sleep 3
    exit 0
}

# Restaurar servicios de red
function restaurar_procesos() {
    show_banner
    sudo airmon-ng
    echo -e "$verde Ingresa el nombre de tu interfaz (ej: wlan0):"
    read -rp " #> " antena

    echo -e "$verde[+] Restaurando servicios de red..."
    sudo systemctl restart NetworkManager
    sudo service wpa_supplicant start
    sudo ifconfig "$antena" down
    sudo iw dev "$antena" set type managed
    sudo ifconfig "$antena" up

    echo -e "$verde[+] Servicios restaurados correctamente."
    sleep 2
    menu
}

# Salir
function salir() {
    echo -e "$verde[*] Saliendo del script. Recuerda restaurar los servicios si no lo hiciste."
    sleep 1
    clear
    exit 0
}

# Comprobar si es root
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "$rojo[!] Debes ejecutar este script como root (usa sudo)."
    exit 1
fi

menu
