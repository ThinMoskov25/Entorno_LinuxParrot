#!/bin/bash
# Script para crear la regla "update" en ParrotOS con logs y snapshot

# Ruta donde estarán los logs
LOG_DIR="/home/moskov/Desktop/Moskov/Apps/Update/logs"
mkdir -p "$LOG_DIR"

# Archivo destino del comando update
DESTINO="/usr/local/bin/update"

# Crear el script global "update"
sudo tee "$DESTINO" > /dev/null <<'EOF'
#!/bin/bash
LOG_DIR="/home/moskov/Desktop/Moskov/Apps/Update/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"

{
    echo "========== [$(date)] INICIO UPDATE =========="
    echo "[+] Ejecutando regla update en ParrotOS..."

    # Verificar si timeshift está instalado
    if command -v timeshift-gtk >/dev/null 2>&1 || command -v timeshift >/dev/null 2>&1; then
        echo "[+] Creando snapshot con Timeshift antes de actualizar..."
        sudo timeshift --create --comments "Auto-snapshot antes de update" --tags D
    else
        echo "[!] Timeshift no está instalado o no se encontró el comando, se omitirá el backup."
    fi

    # Actualizar el sistema
    echo "[+] Iniciando actualización con parrot-upgrade..."
    sudo parrot-upgrade -y

    echo "========== [$(date)] FIN UPDATE =========="
} | tee -a "$LOG_FILE"
EOF

# Dar permisos de ejecución
sudo chmod +x "$DESTINO"

# Recargar zshrc para que el alias o path esté actualizado
if [ -f ~/.zshrc ]; then
    echo "[+] Recargando configuración de Zsh..."
    source ~/.zshrc
fi

echo "[✓] Regla 'update' creada correctamente."
echo "[✓] Los logs se guardarán en: $LOG_DIR"
echo "[✓] Ya puedes usar el comando: update"
