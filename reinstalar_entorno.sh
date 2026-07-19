#!/bin/bash
# =============================================================================
# REINSTALACIÓN COMPLETA DEL ENTORNO - Parrot Security / Debian
# =============================================================================
# Este script reproduce el entorno completo en una máquina nueva o VM.
# Uso: sudo bash reinstalar_entorno.sh
#
# Requisitos previos:
#   - Parrot Security 6.x o Debian 12+ instalado (base mínima)
#   - Conexión a internet
#   - Ejecutar como root (sudo)
# =============================================================================

set -o pipefail

# --- CONFIGURACIÓN ---
USUARIO="moskov"
HOME_DIR="/home/$USUARIO"
LOG_DIR="$HOME_DIR/Documentos/OptimizacionEntorno/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/reinstalacion-$(date +%Y%m%d-%H%M%S).log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

# --- VERIFICACIONES ---
if [ "$EUID" -ne 0 ]; then
    echo "Este script requiere sudo. Ejecuta: sudo bash $0"
    exit 1
fi

echo "============================================" | tee -a "$LOG_FILE"
echo "  Reinstalación del Entorno Completo"       | tee -a "$LOG_FILE"
echo "  Fecha: $(date)"                            | tee -a "$LOG_FILE"
echo "  Usuario: $USUARIO"                         | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# =============================================================================
# PASO 1: ACTUALIZAR SISTEMA
# =============================================================================
log "PASO 1/8: Actualizando sistema..."
apt update >> "$LOG_FILE" 2>&1
apt upgrade -y >> "$LOG_FILE" 2>&1
log "  Sistema actualizado"

# =============================================================================
# PASO 2: PAQUETES BASE DEL ENTORNO GRÁFICO (WM + Rice)
# =============================================================================
log "PASO 2/8: Instalando entorno gráfico (bspwm + rice)..."

apt install -y \
    bspwm \
    sxhkd \
    polybar \
    picom \
    rofi \
    feh \
    neofetch \
    xclip \
    wmname \
    xdotool \
    i3lock \
    >> "$LOG_FILE" 2>&1

log "  WM y componentes gráficos instalados"

# =============================================================================
# PASO 3: TERMINAL Y SHELL
# =============================================================================
log "PASO 3/8: Instalando terminal y shell..."

apt install -y \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    bat \
    stow \
    git \
    curl \
    wget \
    net-tools \
    >> "$LOG_FILE" 2>&1

# lsd (puede no estar en repos, instalar desde GitHub)
if ! command -v lsd &>/dev/null; then
    log "  Instalando lsd desde GitHub..."
    LSD_VERSION="1.1.5"
    wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-musl_${LSD_VERSION}_amd64.deb" -O /tmp/lsd.deb
    dpkg -i /tmp/lsd.deb >> "$LOG_FILE" 2>&1 || apt install -f -y >> "$LOG_FILE" 2>&1
    rm -f /tmp/lsd.deb
fi

# fzf
if [ ! -d "$HOME_DIR/.fzf" ]; then
    log "  Instalando fzf..."
    su - "$USUARIO" -c "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all" >> "$LOG_FILE" 2>&1
fi

# Powerlevel10k
if [ ! -d "$HOME_DIR/powerlevel10k" ]; then
    log "  Instalando Powerlevel10k..."
    su - "$USUARIO" -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k" >> "$LOG_FILE" 2>&1
fi

# Cambiar shell a zsh
chsh -s /usr/bin/zsh "$USUARIO" >> "$LOG_FILE" 2>&1

# Plugin sudo para zsh
if [ ! -f /usr/share/zsh-sudo/sudo.plugin.zsh ]; then
    mkdir -p /usr/share/zsh-sudo
    wget -q "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh" -O /usr/share/zsh-sudo/sudo.plugin.zsh
fi

log "  Terminal y shell configurados"

# =============================================================================
# PASO 4: KITTY (Terminal emulator)
# =============================================================================
log "PASO 4/8: Instalando Kitty..."

if [ ! -d /opt/kitty ]; then
    mkdir -p /opt/kitty
    curl -sL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin dest=/opt/kitty launch=n >> "$LOG_FILE" 2>&1
    # Mover al lugar correcto si se instaló en subdirectorio
    if [ -d /opt/kitty/kitty.app ]; then
        mv /opt/kitty/kitty.app/* /opt/kitty/ 2>/dev/null || true
    fi
fi
log "  Kitty instalado en /opt/kitty"

# =============================================================================
# PASO 5: NEOVIM + NvChad
# =============================================================================
log "PASO 5/8: Instalando Neovim + NvChad..."

if [ ! -d /opt/nvim ]; then
    mkdir -p /opt/nvim
    NVIM_VERSION="v0.10.3"
    wget -q "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" -O /tmp/nvim.tar.gz
    tar -xzf /tmp/nvim.tar.gz -C /opt/nvim/ >> "$LOG_FILE" 2>&1
    rm -f /tmp/nvim.tar.gz
fi

# NvChad se configura con los dotfiles (nvim config ya está en el repo)
log "  Neovim instalado en /opt/nvim"

# =============================================================================
# PASO 6: HERRAMIENTAS DE SEGURIDAD
# =============================================================================
log "PASO 6/8: Instalando herramientas de seguridad..."

apt install -y \
    nmap \
    wireshark \
    aircrack-ng \
    hashcat \
    john \
    hydra \
    sqlmap \
    nikto \
    gobuster \
    ffuf \
    responder \
    wifite \
    python3-impacket \
    impacket-scripts \
    metasploit-framework \
    burpsuite \
    >> "$LOG_FILE" 2>&1 || warn "  Algunos paquetes de seguridad no se instalaron (pueden requerir repos de Parrot)"

# pspy
if [ ! -d /opt/pspy ]; then
    mkdir -p /opt/pspy
    wget -q "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64" -O /opt/pspy/pspy64
    chmod +x /opt/pspy/pspy64
fi

log "  Herramientas de seguridad instaladas"

# =============================================================================
# PASO 7: ENLAZAR DOTFILES CON STOW
# =============================================================================
log "PASO 7/8: Enlazando dotfiles..."

DOTFILES_DIR="$HOME_DIR/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"

    PACKAGES=(zsh bash bspwm sxhkd kitty picom polybar rofi nvim neofetch)
    for pkg in "${PACKAGES[@]}"; do
        if [ -d "$DOTFILES_DIR/$pkg" ]; then
            stow --adopt "$pkg" -t "$HOME_DIR" >> "$LOG_FILE" 2>&1 || true
        fi
    done
    # Restaurar los archivos del repo
    git checkout . >> "$LOG_FILE" 2>&1 || true
    log "  Dotfiles enlazados correctamente"
else
    warn "  No se encontró ~/dotfiles/. Clona tu repositorio primero:"
    warn "  git clone <tu-repo> ~/dotfiles"
fi

# Permisos correctos
chown -R "$USUARIO:$USUARIO" "$HOME_DIR"

# =============================================================================
# PASO 8: HARDENING BÁSICO (UFW)
# =============================================================================
log "PASO 8/8: Configurando firewall UFW..."

apt install -y ufw >> "$LOG_FILE" 2>&1

ufw --force reset >> "$LOG_FILE" 2>&1
ufw default deny incoming >> "$LOG_FILE" 2>&1
ufw default allow outgoing >> "$LOG_FILE" 2>&1
ufw allow in on lo >> "$LOG_FILE" 2>&1
ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1
ufw allow 7070/tcp comment 'AnyDesk' >> "$LOG_FILE" 2>&1
ufw allow 1194/udp comment 'OpenVPN' >> "$LOG_FILE" 2>&1
ufw allow 51820/udp comment 'WireGuard' >> "$LOG_FILE" 2>&1

# Bloquear pings
sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/' /etc/ufw/before.rules 2>/dev/null || true

ufw logging low >> "$LOG_FILE" 2>&1
ufw --force enable >> "$LOG_FILE" 2>&1

log "  UFW configurado y activo"

# =============================================================================
# PASO EXTRA: Crear estructura de carpetas de trabajo
# =============================================================================
log "Creando estructura de carpetas..."

su - "$USUARIO" -c "
mkdir -p ~/Desktop/Moskov/{Apps,Ciberseguridad/{Documentos,Estudio,Local_Services,Tools,VPN},Fondo_Pantalla,Kiro}
mkdir -p ~/Desktop/Moskov/Ciberseguridad/Tools/{AllTools,Auto_Tools,CellPhone-Tools,Escaneo,Herramientas,Ngrok,Phishing,Wifi_Conect}
mkdir -p ~/Desktop/Moskov/Ciberseguridad/Estudio/{Clases_Python,Laboratorios,Maquinas_HTB,Network_Drive}
mkdir -p ~/Desktop/Moskov/Apps/Update/logs
mkdir -p ~/Documentos/OptimizacionEntorno/logs
mkdir -p ~/.config/bin
" >> "$LOG_FILE" 2>&1

log "  Estructura de carpetas creada"

# =============================================================================
# PASO EXTRA: Crear comando global 'update'
# =============================================================================
log "Creando comando global 'update'..."

cat > /usr/local/bin/update <<'UPDATEEOF'
#!/bin/bash
LOG_DIR="/home/moskov/Desktop/Moskov/Apps/Update/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"

{
    echo "========== [$(date)] INICIO UPDATE =========="
    echo "[+] Ejecutando regla update en ParrotOS..."

    if command -v timeshift >/dev/null 2>&1; then
        echo "[+] Creando snapshot con Timeshift antes de actualizar..."
        sudo timeshift --create --comments "Auto-snapshot antes de update" --tags D
    else
        echo "[!] Timeshift no está instalado, se omitirá el backup."
    fi

    echo "[+] Iniciando actualización con parrot-upgrade..."
    sudo parrot-upgrade -y

    echo "========== [$(date)] FIN UPDATE =========="
} | tee -a "$LOG_FILE"
UPDATEEOF

chmod +x /usr/local/bin/update
log "  Comando 'update' creado en /usr/local/bin/update"

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo "" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "  REINSTALACIÓN COMPLETADA"                   | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "  [✓] Sistema actualizado"                    | tee -a "$LOG_FILE"
echo "  [✓] bspwm + sxhkd + polybar + picom + rofi" | tee -a "$LOG_FILE"
echo "  [✓] Kitty + Zsh + Powerlevel10k"            | tee -a "$LOG_FILE"
echo "  [✓] Neovim + NvChad"                        | tee -a "$LOG_FILE"
echo "  [✓] Herramientas de seguridad"              | tee -a "$LOG_FILE"
echo "  [✓] Dotfiles enlazados con stow"            | tee -a "$LOG_FILE"
echo "  [✓] UFW firewall activo"                    | tee -a "$LOG_FILE"
echo "  [✓] Estructura de carpetas creada"          | tee -a "$LOG_FILE"
echo "  [✓] Comando 'update' disponible"            | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "  Log: $LOG_FILE"                             | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "  SIGUIENTE PASO:"                            | tee -a "$LOG_FILE"
echo "    1. Reinicia la sesión (logout/login)"     | tee -a "$LOG_FILE"
echo "    2. Selecciona bspwm como WM en el login"  | tee -a "$LOG_FILE"
echo "    3. Copia tu wallpaper a ~/Desktop/Moskov/Fondo_Pantalla/fondo.jpeg" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
