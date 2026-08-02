#!/bin/bash

# Ruta base (ya existente)
BASE_DIR="/home/moskov/Desktop/Moskov/Apps/Google_Chrome"
LOG_DIR="$BASE_DIR/logs"

# Crear carpeta de logs si no existe
mkdir -p "$LOG_DIR"

# Fecha y nombre del log
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/act_chrome_$FECHA.log"

# Función para escribir con timestamp
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

log "=== INICIO DE INSTALACIÓN DE GOOGLE CHROME ==="

# Agregar clave GPG de Google si no existe
KEYRING="/usr/share/keyrings/google-chrome.gpg"
if [ ! -f "$KEYRING" ]; then
    log "Agregando clave GPG oficial de Google..."
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
        sudo gpg --dearmor -o "$KEYRING"
else
    log "Clave GPG ya existe en $KEYRING"
fi

# Agregar repo de Google si no existe
REPO_FILE="/etc/apt/sources.list.d/google-chrome.list"
if [ ! -f "$REPO_FILE" ]; then
    log "Agregando repositorio oficial de Google Chrome..."
    echo "deb [arch=amd64 signed-by=$KEYRING] http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee "$REPO_FILE" > /dev/null
else
    log "Repositorio ya existe en $REPO_FILE"
fi

# Actualizar solo el repo de Chrome
log "Actualizando índices del repositorio de Google Chrome..."
sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/google-chrome.list" \
    -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" >> "$LOG_FILE" 2>&1

# Instalar Google Chrome
log "Instalando Google Chrome..."
sudo apt install -y google-chrome-stable >> "$LOG_FILE" 2>&1

# Verificación final
if command -v google-chrome &> /dev/null; then
    VERSION=$(google-chrome --version 2>/dev/null)
    log "Instalación completada. Versión instalada: $VERSION"
else
    log "[ERROR] No se pudo instalar Google Chrome."
fi

log "=== FIN DEL PROCESO ==="
echo "Proceso finalizado. Revisa el log en: $LOG_FILE"
