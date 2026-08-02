#!/bin/bash

# Instalador de Tor en Parrot OS

set -e

# Colores
verde='\033[0;32m'
rojo='\033[0;31m'
reset='\033[0m'

# Log file
log_file="instalacion_tor_log.txt"

# Función para mostrar título bonito
titulo() {
    echo -e "${verde}\n==> $1${reset}" | tee -a $log_file
}

# Función para registrar el log
log() {
    echo "$1" | tee -a $log_file
}

# Función para instalar Tor
instalar_tor() {
    titulo "Iniciando instalación de Tor"

    # Actualizamos repositorios
    log "Actualizando repositorios..."
    sudo apt update -y | tee -a $log_file

    # Instalamos Tor
    log "Instalando Tor..."
    sudo apt install -y tor deb.torproject.org-keyring | tee -a $log_file

    # Instalamos el Navegador Tor
    log "Instalando Navegador Tor..."
    sudo apt install -y torbrowser-launcher | tee -a $log_file

    # Confirmar instalación
    if command -v torbrowser-launcher &> /dev/null; then
        log "✔️ Navegador Tor instalado correctamente."
    else
        log "❌ Error en la instalación de Tor."
    fi
}

# Opción de instalación de Tor
instalar_tor
