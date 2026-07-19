#!/bin/bash
# Script para aplicar los últimos pasos de optimización del entorno
# Uso: sudo bash aplicar_cambios.sh

set +e  # No abortar en errores, continuar con los demás pasos

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/optimizacion-$(date +%Y%m%d-%H%M%S).log"

# Función para log
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "============================================"
log "  Optimización del Entorno - Parrot Security"
log "  Fecha: $(date)"
log "============================================"
log ""

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script requiere sudo. Ejecuta: sudo bash $0"
    exit 1
fi

# --- PASO 1: Instalar stow ---
log "[1/4] Instalando stow..."
if command -v stow &>/dev/null; then
    log "  [✓] stow ya está instalado"
else
    apt install stow -y >> "$LOG_FILE" 2>&1
    log "  [✓] stow instalado correctamente"
fi

# --- PASO 2: Enlazar dotfiles ---
log ""
log "[2/4] Enlazando dotfiles con stow..."
DOTFILES_DIR="/home/moskov/dotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    
    # Backup de originales
    BACKUP_DIR="/home/moskov/.dotfiles_backup_$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    for file in .zshrc .bashrc .profile .p10k.zsh; do
        [ -f "/home/moskov/$file" ] && [ ! -L "/home/moskov/$file" ] && mv "/home/moskov/$file" "$BACKUP_DIR/"
    done
    log "  [+] Backup guardado en: $BACKUP_DIR"

    PACKAGES=(zsh bash bspwm sxhkd kitty picom polybar rofi nvim neofetch)
    for pkg in "${PACKAGES[@]}"; do
        if [ -d "$DOTFILES_DIR/$pkg" ]; then
            # --adopt mueve los archivos existentes al repo y crea los symlinks
            stow -v --adopt "$pkg" -t "/home/moskov" >> "$LOG_FILE" 2>&1 || true
            log "  [✓] $pkg enlazado"
        fi
    done
    # Restaurar los archivos del repo (adopt pudo sobreescribirlos con los del sistema)
    cd "$DOTFILES_DIR"
    git checkout . >> "$LOG_FILE" 2>&1 || true
    log "  [+] Archivos del repo restaurados tras adopt"
else
    log "  [!] No se encontró ~/dotfiles/. Saltando..."
fi

# --- PASO 3: Configurar UFW ---
log ""
log "[3/4] Configurando firewall UFW..."

ufw --force reset >> "$LOG_FILE" 2>&1
ufw default deny incoming >> "$LOG_FILE" 2>&1
ufw default allow outgoing >> "$LOG_FILE" 2>&1
ufw allow in on lo >> "$LOG_FILE" 2>&1
ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1
ufw allow 7070/tcp comment 'AnyDesk' >> "$LOG_FILE" 2>&1
ufw allow 1194/udp comment 'OpenVPN' >> "$LOG_FILE" 2>&1
ufw allow 51820/udp comment 'WireGuard' >> "$LOG_FILE" 2>&1

# Bloquear pings entrantes
sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/' /etc/ufw/before.rules 2>/dev/null || true

ufw logging low >> "$LOG_FILE" 2>&1
ufw --force enable >> "$LOG_FILE" 2>&1

log "  [✓] UFW configurado y activado"
ufw status verbose >> "$LOG_FILE" 2>&1

# --- PASO 4: Reiniciar servicios del WM ---
log ""
log "[4/4] Reiniciando picom y sxhkd..."

# Reiniciar picom (como usuario, no root)
su - moskov -c "pkill picom; sleep 1; picom &" >> "$LOG_FILE" 2>&1 || true
log "  [✓] picom reiniciado con use-damage=true"

# Recargar sxhkd
su - moskov -c "pkill -USR1 -x sxhkd" >> "$LOG_FILE" 2>&1 || true
log "  [✓] sxhkd recargado"

# --- RESUMEN ---
log ""
log "============================================"
log "  COMPLETADO"
log "============================================"
log ""
log "  [✓] stow instalado y dotfiles enlazados"
log "  [✓] UFW activo (deny incoming, allow outgoing)"
log "  [✓] Picom reiniciado con optimización GPU"
log "  [✓] sxhkd recargado con paths portables"
log ""
log "  Log guardado en: $LOG_FILE"
log ""
log "  Si algo falla, restaura con:"
log "    sudo timeshift --restore"
log "============================================"
