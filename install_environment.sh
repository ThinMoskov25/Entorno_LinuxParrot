#!/bin/bash
# =============================================================================
# install_environment.sh - Moskov Environment v3.0
# by Moskov - SrBalduR
# Uso: sudo bash install_environment.sh [--auto]
# Compatibilidad: Parrot Security 6.x / Debian 12+
# =============================================================================
# Arquitectura Zero-Intervention:
#   --auto : Instalacion COMPLETA desatendida (sin menu, sin confirmaciones)
#   Pre-Flight APT/DPKG auto-repair (candados, procesos zombie)
#   X11-Aware Display Logic (no mata sesion grafica viva)
#   Aislamiento modular: fallos APT NO bloquean despliegue de dotfiles
#   Permisos imperativos finales SIEMPRE se ejecutan
#   Clonacion TOTAL del entorno: paquetes, herramientas, apps, configs
# =============================================================================

set -uo pipefail

# =============================================================================
# MODULE 0: ELEVACION, ARGUMENTOS Y EXPORTS
# =============================================================================

# Detectar flag --auto y --user ANTES de la elevacion
AUTO_MODE=0
FORCED_USER=""
for arg in "$@"; do
    [[ "$arg" == "--auto" ]] && AUTO_MODE=1
    [[ "$arg" == --user=* ]] && FORCED_USER="${arg#--user=}"
done

if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

# Zero-Block APT
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export NEEDRESTART_MODE=a
export UCF_FORCE_CONFFOLD=YES

# =============================================================================
# MODULE 1: DETECCION INQUEBRANTABLE DE USUARIO REAL
# =============================================================================

detect_real_user() {
    local candidate=""
    # Prioridad 0: usuario forzado por parametro --user=nombre
    [[ -n "${FORCED_USER:-}" ]] && candidate="$FORCED_USER"
    # Prioridad 1: SUDO_USER (la fuente mas confiable cuando se usa sudo)
    [[ -z "$candidate" || "$candidate" == "root" ]] && candidate="${SUDO_USER:-}"
    # Prioridad 2: logname (detecta usuario de sesion de login)
    [[ -z "$candidate" || "$candidate" == "root" ]] && candidate="$(logname 2>/dev/null || true)"
    # Prioridad 3: who (usuario logueado en TTY)
    [[ -z "$candidate" || "$candidate" == "root" ]] && candidate="$(who | grep -v root | awk 'NR==1{print $1}')"
    # Prioridad 4: propietario del directorio del script (quien hizo git clone)
    [[ -z "$candidate" || "$candidate" == "root" ]] && candidate="$(stat -c '%U' "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || true)"
    # Prioridad 5: primer usuario no-root con UID >= 1000
    [[ -z "$candidate" || "$candidate" == "root" ]] && candidate="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' /etc/passwd)"
    if [[ -z "$candidate" || "$candidate" == "root" ]]; then
        echo "ERROR CRITICO: No se detecto usuario real (no root)."
        echo "Ejecuta: sudo bash $0 --user=TU_USUARIO"
        exit 1
    fi
    echo "$candidate"
}

REAL_USER="$(detect_real_user)"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    echo "ERROR: HOME no encontrado para '$REAL_USER' ($REAL_HOME)"
    exit 1
fi

# Confirmacion visible de usuario detectado
echo ""
echo "=============================================="
echo "  USUARIO DETECTADO: $REAL_USER"
echo "  HOME:              $REAL_HOME"
echo "  Metodo:            SUDO_USER=${SUDO_USER:-vacio} | logname=$(logname 2>/dev/null || echo N/A)"
echo "=============================================="
echo ""

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOSKOV_DIR="$REAL_HOME/Desktop/$REAL_USER"
CIBER_DIR="$MOSKOV_DIR/Ciberseguridad"
LOG_DIR="$REAL_HOME/install_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
ERRORS=0

APT_FLAGS=(-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

# =============================================================================
# MODULE 2: DETECCION DE SESION GRAFICA VIVA
# =============================================================================

is_gui_session_active() {
    [[ -n "${DISPLAY:-}" ]] && return 0
    pgrep -x lightdm &>/dev/null && return 0
    pgrep -x Xorg &>/dev/null && return 0
    pgrep -x X &>/dev/null && return 0
    if [[ -f "/proc/$(pgrep -u "$REAL_USER" -x bspwm 2>/dev/null | head -1)/environ" ]] 2>/dev/null; then
        return 0
    fi
    return 1
}

GUI_ACTIVE=0
is_gui_session_active && GUI_ACTIVE=1

# =============================================================================
# MODULE 3: INTERFAZ DE USUARIO (UI)
# =============================================================================

G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

banner() {
    clear
    echo -e "${C}"
    echo "  ========================================================"
    echo "       INSTALADOR DE ENTORNO - Moskov Environment v3.0"
    echo "                  by Moskov - SrBalduR"
    echo "  ========================================================"
    echo "   Instalar . Reinstalar . Actualizar"
    echo "  ========================================================"
    echo -e "${RST}"
}

log_ok()   { echo -e "    ${G}[+]${RST} $1" | tee -a "$LOG_FILE"; }
log_proc() { echo -e "    ${Y}[*]${RST} $1" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "    ${R}[!]${RST} $1" | tee -a "$LOG_FILE"; ((ERRORS++)); }
log_info() { echo -e "    ${DIM}$1${RST}" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "    ${Y}[~]${RST} $1" | tee -a "$LOG_FILE"; }

check_status() { [[ $? -eq 0 ]] && log_ok "$1" || log_err "$2"; }

run_as_user() {
    su - "$REAL_USER" -c "export HOME=$REAL_HOME; cd $REAL_HOME; $1"
}

# =============================================================================
# PRE-LIMPIEZA
# =============================================================================

pre_limpieza() {
    local hay=0
    [[ -d "$MOSKOV_DIR" ]] && hay=1
    [[ -d "$REAL_HOME/.config/bspwm" ]] && hay=1
    [[ -d "$REAL_HOME/.config/polybar" ]] && hay=1

    if [[ $hay -eq 1 ]]; then
        if [[ $AUTO_MODE -eq 1 ]]; then
            log_proc "Modo auto: eliminando entorno previo..."
        else
            echo ""
            echo -e "    ${Y}[!] Entorno previo detectado en $REAL_HOME${RST}"
            read -rp "    Eliminar estructura previa? (s/n): " confirm
            [[ "$confirm" != "s" && "$confirm" != "S" ]] && { log_info "Omitido"; return; }
        fi
        log_proc "Eliminando entorno previo..."
        rm -rf "$MOSKOV_DIR"
        rm -rf "$REAL_HOME/.config/bspwm" "$REAL_HOME/.config/sxhkd"
        rm -rf "$REAL_HOME/.config/polybar" "$REAL_HOME/.config/picom"
        rm -rf "$REAL_HOME/.config/kitty" "$REAL_HOME/.config/rofi"
        rm -rf "$REAL_HOME/.config/nvim" "$REAL_HOME/.config/neofetch"
        rm -f "$REAL_HOME/.zshrc" "$REAL_HOME/.p10k.zsh" "$REAL_HOME/.xinitrc"
        rm -rf "$REAL_HOME/.cache"
        log_ok "Entorno previo eliminado"
    fi
}

# =============================================================================
# FASE 0: PRE-FLIGHT APT/DPKG AUTO-REPAIR
# =============================================================================

fase_preflight() {
    banner
    echo -e "  ${B}FASE 0: Pre-Flight - Saneamiento APT/DPKG${RST}\n"

    log_proc "Eliminando procesos APT/DPKG residuales..."
    killall -9 apt apt-get dpkg 2>/dev/null || true
    fuser -k /var/lib/dpkg/lock 2>/dev/null || true
    fuser -k /var/lib/apt/lists/lock 2>/dev/null || true
    fuser -k /var/cache/apt/archives/lock 2>/dev/null || true
    log_ok "Procesos residuales eliminados"

    log_proc "Liberando candados..."
    rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock
    log_ok "Candados liberados"

    log_proc "Reparando dpkg..."
    dpkg --configure -a --force-confdef --force-confold >> "$LOG_FILE" 2>&1 || true
    log_ok "dpkg reparado"

    log_proc "Reparando dependencias..."
    apt-get install -f -y "${APT_FLAGS[@]}" >> "$LOG_FILE" 2>&1 || true
    apt-get clean >> "$LOG_FILE" 2>&1 || true
    log_ok "Sistema de paquetes saneado"

    echo ""
    log_ok "PRE-FLIGHT COMPLETADO"
}

# =============================================================================
# FASE 1: PURGA Y PREVENCION DE CONFLICTOS (X11-Aware)
# =============================================================================

fase_purga() {
    banner
    echo -e "  ${B}FASE 1/8: Purga y prevencion de conflictos${RST}\n"

    systemctl mask isc-dhcp-server isc-dhcp-server6 2>/dev/null || true
    log_ok "Servicios conflictivos enmascarados"

    if [[ $GUI_ACTIVE -eq 1 ]]; then
        log_warn "GUI activa - omitiendo purga de DMs"
    else
        systemctl stop sddm gdm3 gdm display-manager 2>/dev/null || true
        systemctl disable sddm gdm3 gdm 2>/dev/null || true
        log_ok "DMs anteriores deshabilitados (TTY)"
    fi

    rm -rf /etc/sddm.conf /etc/sddm.conf.d /var/lib/sddm 2>/dev/null
    systemctl unmask NetworkManager 2>/dev/null || true
    systemctl enable NetworkManager 2>/dev/null || true
    log_ok "NetworkManager asegurado"

    echo ""
    log_ok "FASE 1 COMPLETADA"
}

# =============================================================================
# FASE 2: PAQUETES COMPLETOS (Entorno + Pentesting + Desarrollo)
# =============================================================================

fase_paquetes() {
    banner
    echo -e "  ${B}FASE 2/8: Paquetes COMPLETOS (Zero-Block, X11-Aware)${RST}\n"

    local APT_SUCCESS=0

    {
        log_proc "apt-get update..."
        apt-get update -qq >> "$LOG_FILE" 2>&1 || true

        # --- PAQUETES XORG/DISPLAY ---
        local PKGS_XORG=(
            xorg xserver-xorg-core xinit
            lightdm lightdm-gtk-greeter
        )

        # --- ENTORNO DE ESCRITORIO ---
        local PKGS_DESKTOP=(
            bspwm sxhkd polybar picom rofi
            feh maim xclip xdotool xdo wmname i3lock x11-xserver-utils
            flameshot imagemagick xterm gnome-terminal
        )

        # --- SHELL Y TERMINAL ---
        local PKGS_SHELL=(
            zsh zsh-autosuggestions zsh-syntax-highlighting fzf bat
            tmux ranger htop iftop nload
        )

        # --- DESARROLLO ---
        local PKGS_DEV=(
            git curl wget stow build-essential
            golang-go nodejs npm python3 python3-pip python3-dev
            default-jdk ruby ruby-dev ruby-full
            cmake meson ninja-build nasm
            libncurses-dev libreadline-dev libssl-dev libsqlite3-dev
            libpcap-dev libconfig-dev libev-dev libx11-xcb-dev
            libxcb1-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-randr0-dev
            libxcb-util-dev libxcb-keysyms1-dev libxcb-shape0-dev
            pkg-config autoconf libtool
        )

        # --- REDES Y SERVICIOS ---
        local PKGS_NETWORK=(
            net-tools nmap masscan netdiscover traceroute
            samba nfs-common nfs-kernel-server sshfs cifs-utils
            ufw gufw socat proxychains sshpass
            network-manager network-manager-openvpn
            network-manager-openconnect network-manager-vpnc
            postfix postgresql sqlite3
        )

        # --- PENTESTING / SEGURIDAD (clone completo) ---
        local PKGS_SECURITY=(
            aircrack-ng bettercap binwalk cewl commix crunch
            dmitry dnsenum enum4linux fcrackzip
            gobuster hashcat hashid hping3 hydra
            john joomscan macchanger mdk4
            nikto nishang onesixtyone
            smbmap smtp-user-enum sqlmap
            tshark websploit wfuzz whois wireshark
            metasploit-framework
        )

        # --- UTILIDADES ---
        local PKGS_UTILS=(
            unzip zip rsync p7zip-full
            fonts-font-awesome brightnessctl pamixer
            timeshift gparted remmina vim
            flatpak torbrowser-launcher
        )

        # Instalar segun contexto grafico
        if [[ $GUI_ACTIVE -eq 1 ]]; then
            log_warn "GUI activa: Xorg sin --reinstall"
            apt-get install -y "${APT_FLAGS[@]}" "${PKGS_XORG[@]}" >> "$LOG_FILE" 2>&1 || true
        else
            log_proc "Instalando Xorg completo (TTY)..."
            apt-get install --reinstall -y "${APT_FLAGS[@]}" "${PKGS_XORG[@]}" >> "$LOG_FILE" 2>&1 || true
        fi

        log_proc "Instalando entorno de escritorio..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_DESKTOP[@]}" >> "$LOG_FILE" 2>&1 || {
            log_warn "Instalacion grupal fallo - instalando paquetes uno a uno..."
            for pkg in "${PKGS_DESKTOP[@]}"; do
                apt-get install -y "${APT_FLAGS[@]}" "$pkg" >> "$LOG_FILE" 2>&1 || log_warn "Paquete no disponible: $pkg"
            done
        }
        # neofetch removido de Parrot/Debian 13, usar fastfetch como reemplazo
        apt-get install -y "${APT_FLAGS[@]}" fastfetch >> "$LOG_FILE" 2>&1 || \
            apt-get install -y "${APT_FLAGS[@]}" neofetch >> "$LOG_FILE" 2>&1 || true

        log_proc "Instalando shell y terminal..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_SHELL[@]}" >> "$LOG_FILE" 2>&1 || true

        log_proc "Instalando desarrollo..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_DEV[@]}" >> "$LOG_FILE" 2>&1 || true

        log_proc "Instalando redes y servicios..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_NETWORK[@]}" >> "$LOG_FILE" 2>&1 || true

        log_proc "Instalando herramientas de seguridad..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_SECURITY[@]}" >> "$LOG_FILE" 2>&1 || true

        log_proc "Instalando utilidades..."
        apt-get install -y "${APT_FLAGS[@]}" "${PKGS_UTILS[@]}" >> "$LOG_FILE" 2>&1 || true

        APT_SUCCESS=1

        # LightDM como DM predeterminado
        echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections 2>/dev/null || true
        dpkg-reconfigure -f noninteractive lightdm >> "$LOG_FILE" 2>&1 || true
        log_ok "LightDM forzado como predeterminado"

        # lsd
        log_proc "lsd..."
        wget -q "https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd-musl_1.1.5_amd64.deb" -O /tmp/lsd.deb 2>/dev/null || true
        dpkg -i /tmp/lsd.deb >> "$LOG_FILE" 2>&1 || apt-get install -f -y "${APT_FLAGS[@]}" >> "$LOG_FILE" 2>&1 || true
        rm -f /tmp/lsd.deb
        log_ok "lsd instalado"

    } || {
        log_err "BLOQUE APT FALLO - continuando a dotfiles"
    }

    echo ""
    log_ok "FASE 2 COMPLETADA"
}

# =============================================================================
# FASE 3: SESION X11 + BSPWM
# =============================================================================

fase_xsession() {
    banner
    echo -e "  ${B}FASE 3/8: Sesion BSPWM para LightDM${RST}\n"

    # --- bspwm-session: script ultra-defensivo ---
    cat > /usr/bin/bspwm-session <<'BSEOF'
#!/bin/sh
# Moskov Environment - BSPWM Session Launcher
# Este script es ejecutado por LightDM al iniciar sesion

# 1. Garantizar HOME y PATH completo
export HOME="${HOME:-$(getent passwd $(id -un) | cut -d: -f6)}"
export XDG_CURRENT_DESKTOP="bspwm"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
export XDG_CONFIG_HOME="$HOME/.config"

# 2. Log de depuracion
mkdir -p "$HOME/install_logs"
LOGF="$HOME/install_logs/bspwm-session.log"
echo "=== [$(date)] SESSION START ===" >> "$LOGF"
echo "USER=$(id -un) HOME=$HOME" >> "$LOGF"
echo "PATH=$PATH" >> "$LOGF"

# 3. Detectar binarios (APT instala en /usr/bin, compilado en /usr/local/bin)
SXHKD_BIN="$(command -v sxhkd 2>/dev/null)"
BSPWM_BIN="$(command -v bspwm 2>/dev/null)"

if [ -z "$SXHKD_BIN" ]; then
    echo "ERROR: sxhkd no encontrado en PATH" >> "$LOGF"
fi
if [ -z "$BSPWM_BIN" ]; then
    echo "ERROR: bspwm no encontrado en PATH" >> "$LOGF"
    exit 1
fi

echo "SXHKD_BIN=$SXHKD_BIN" >> "$LOGF"
echo "BSPWM_BIN=$BSPWM_BIN" >> "$LOGF"

# 4. Verificar que bspwmrc existe y es ejecutable
BSPWMRC="$HOME/.config/bspwm/bspwmrc"
if [ ! -f "$BSPWMRC" ]; then
    echo "ERROR: $BSPWMRC no existe, creando minimo" >> "$LOGF"
    mkdir -p "$HOME/.config/bspwm"
    echo '#!/bin/sh' > "$BSPWMRC"
    echo 'bspc monitor -d I II III IV V' >> "$BSPWMRC"
fi
chmod +x "$BSPWMRC"

# 5. Lanzar sxhkd
SXHKDRC="$HOME/.config/sxhkd/sxhkdrc"
if [ -n "$SXHKD_BIN" ] && [ -f "$SXHKDRC" ]; then
    "$SXHKD_BIN" -c "$SXHKDRC" >> "$LOGF" 2>&1 &
    echo "sxhkd PID=$!" >> "$LOGF"
elif [ -n "$SXHKD_BIN" ]; then
    "$SXHKD_BIN" >> "$LOGF" 2>&1 &
    echo "sxhkd (default) PID=$!" >> "$LOGF"
else
    echo "WARN: sxhkd no disponible" >> "$LOGF"
fi

# 6. Ejecutar bspwm (DEBE ser exec para mantener la sesion viva)
echo "Launching: $BSPWM_BIN -c $BSPWMRC" >> "$LOGF"
exec "$BSPWM_BIN" -c "$BSPWMRC"
BSEOF
    chmod 755 /usr/bin/bspwm-session
    log_ok "bspwm-session creado"

    # --- Registrar sesion en LightDM ---
    mkdir -p /usr/share/xsessions
    # Eliminar otros .desktop de bspwm que el paquete APT pueda haber creado
    rm -f /usr/share/xsessions/bspwm-session.desktop 2>/dev/null

    cat > /usr/share/xsessions/bspwm.desktop <<'EOF'
[Desktop Entry]
Name=BSPWM
Comment=Binary space partitioning window manager
Exec=/usr/bin/bspwm-session
Type=Application
DesktopNames=BSPWM
Keywords=tiling;wm;bspwm;
EOF
    chmod 644 /usr/share/xsessions/bspwm.desktop
    log_ok "bspwm.desktop registrado"

    # --- Forzar LightDM a usar sesion BSPWM por defecto ---
    mkdir -p /etc/lightdm
    cat > /etc/lightdm/lightdm.conf <<'EOF'
[Seat:*]
autologin-user=
user-session=bspwm
greeter-session=lightdm-gtk-greeter
EOF
    log_ok "LightDM configurado: user-session=bspwm"
    # --- Configurar greeter para que no sea pantalla blanca ---
    cat > /etc/lightdm/lightdm-gtk-greeter.conf <<GREETEREOF
[greeter]
theme-name = Adwaita-dark
icon-theme-name = Adwaita
font-name = Sans 11
background = /usr/share/backgrounds/default.png
user-background = true
default-user-image = /usr/share/icons/Adwaita/256x256/status/avatar-default-symbolic.svg
hide-user-image = false
GREETEREOF
    # Intentar usar wallpaper propio si existe
    if [[ -f "$MOSKOV_DIR/Fondo_Pantalla/fondo.jpeg" ]]; then
        sed -i "s|background = .*|background = $MOSKOV_DIR/Fondo_Pantalla/fondo.jpeg|" /etc/lightdm/lightdm-gtk-greeter.conf
    fi
    log_ok "Greeter GTK configurado (tema oscuro)"

    # --- .xsession como fallback absoluto ---
    cat > "$REAL_HOME/.xsession" <<'XEOF'
#!/bin/sh
exec /usr/bin/bspwm-session
XEOF
    chmod +x "$REAL_HOME/.xsession"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.xsession"
    log_ok ".xsession fallback"

    # --- Habilitar LightDM ---
    if [[ $GUI_ACTIVE -eq 1 ]]; then
        systemctl enable lightdm >> "$LOG_FILE" 2>&1 || true
    else
        systemctl disable sddm gdm3 2>/dev/null || true
        systemctl mask sddm gdm3 2>/dev/null || true
        systemctl unmask lightdm 2>/dev/null || true
        systemctl enable lightdm >> "$LOG_FILE" 2>&1 || true
        systemctl set-default graphical.target >> "$LOG_FILE" 2>&1 || true
    fi
    log_ok "LightDM habilitado"

    echo ""
    log_ok "FASE 3 COMPLETADA"
}

# =============================================================================
# FASE 4: BINARIOS PORTABLES (Kitty, Neovim, P10k, fzf)
# =============================================================================

fase_binarios() {
    banner
    echo -e "  ${B}FASE 4/8: Binarios portables${RST}\n"

    # Kitty
    log_proc "Kitty..."
    rm -rf /opt/kitty; mkdir -p /opt/kitty
    curl -sL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin dest=/opt/kitty launch=n >> "$LOG_FILE" 2>&1 || true
    [[ -d /opt/kitty/kitty.app ]] && cp -r /opt/kitty/kitty.app/* /opt/kitty/ && rm -rf /opt/kitty/kitty.app
    ln -sf /opt/kitty/bin/kitty /usr/local/bin/kitty
    log_ok "Kitty"

    # Neovim
    log_proc "Neovim..."
    rm -rf /opt/nvim; mkdir -p /opt/nvim
    wget -q "https://github.com/neovim/neovim/releases/download/v0.10.3/nvim-linux-x86_64.tar.gz" -O /tmp/nvim.tar.gz 2>/dev/null || true
    if [[ -f /tmp/nvim.tar.gz ]]; then
        tar -xzf /tmp/nvim.tar.gz -C /opt/nvim/ --strip-components=1 >> "$LOG_FILE" 2>&1
        ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        rm -f /tmp/nvim.tar.gz
        log_ok "Neovim"
    else
        log_err "Error descargando Neovim"
    fi

    # Powerlevel10k
    log_proc "Powerlevel10k..."
    rm -rf "$REAL_HOME/powerlevel10k"
    run_as_user "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $REAL_HOME/powerlevel10k" >> "$LOG_FILE" 2>&1 || true
    log_ok "Powerlevel10k"

    # fzf
    log_proc "fzf..."
    rm -rf "$REAL_HOME/.fzf"
    run_as_user "git clone --depth 1 https://github.com/junegunn/fzf.git $REAL_HOME/.fzf && $REAL_HOME/.fzf/install --all" >> "$LOG_FILE" 2>&1 || true
    log_ok "fzf"

    # Plugin sudo zsh
    mkdir -p /usr/share/zsh-sudo
    wget -q "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh" \
        -O /usr/share/zsh-sudo/sudo.plugin.zsh 2>/dev/null || true
    log_ok "Plugin sudo zsh"

    echo ""
    log_ok "FASE 4 COMPLETADA"
}

# =============================================================================
# FASE 5: HERRAMIENTAS MANUALES (/opt/ + gems + pip)
# =============================================================================
# Instala todo lo que NO viene de APT: i3lock-fancy, impacket, pspy,
# rofi-themes, ngrok, evil-winrm, wpscan, etc.

fase_herramientas() {
    banner
    echo -e "  ${B}FASE 5/8: Herramientas manuales (opt, gems, pip)${RST}\n"

    # i3lock-fancy
    log_proc "i3lock-fancy..."
    if [[ ! -d /opt/i3lock-fancy ]]; then
        git clone https://github.com/meskarune/i3lock-fancy.git /opt/i3lock-fancy >> "$LOG_FILE" 2>&1 || true
        ln -sf /opt/i3lock-fancy/i3lock-fancy /usr/local/bin/i3lock-fancy
    fi
    log_ok "i3lock-fancy"

    # Rofi themes collection
    log_proc "Rofi themes..."
    if [[ ! -d /opt/rofi-themes-collection ]]; then
        git clone --depth=1 https://github.com/newmanls/rofi-themes-collection.git /opt/rofi-themes-collection >> "$LOG_FILE" 2>&1 || true
    fi
    log_ok "Rofi themes"

    # Impacket (Python)
    log_proc "Impacket..."
    if [[ ! -d /opt/impacket ]]; then
        git clone https://github.com/fortra/impacket.git /opt/impacket >> "$LOG_FILE" 2>&1 || true
        pip3 install /opt/impacket/ --break-system-packages >> "$LOG_FILE" 2>&1 || true
    fi
    log_ok "Impacket"

    # pspy (binarios pre-compilados)
    log_proc "pspy..."
    mkdir -p /opt/pspy
    if [[ ! -f /opt/pspy/pspy64 ]]; then
        wget -q "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64" -O /opt/pspy/pspy64 2>/dev/null || true
        wget -q "https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy32" -O /opt/pspy/pspy32 2>/dev/null || true
        chmod +x /opt/pspy/pspy64 /opt/pspy/pspy32 2>/dev/null || true
    fi
    log_ok "pspy"

    # Ngrok
    log_proc "Ngrok..."
    if ! command -v ngrok &>/dev/null; then
        wget -q "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" -O /tmp/ngrok.tgz 2>/dev/null || true
        if [[ -f /tmp/ngrok.tgz ]]; then
            tar -xzf /tmp/ngrok.tgz -C /usr/local/bin/ >> "$LOG_FILE" 2>&1
            rm -f /tmp/ngrok.tgz
        fi
    fi
    log_ok "Ngrok"

    # Evil-WinRM (Ruby gem)
    log_proc "Evil-WinRM..."
    gem install evil-winrm >> "$LOG_FILE" 2>&1 || true
    log_ok "Evil-WinRM"

    # WPScan (Ruby gem)
    log_proc "WPScan..."
    gem install wpscan >> "$LOG_FILE" 2>&1 || true
    log_ok "WPScan"

    # Python tools via pip
    log_proc "Python tools (pyftpdlib, impacket scripts)..."
    pip3 install pyftpdlib pycryptodome requests beautifulsoup4 --break-system-packages >> "$LOG_FILE" 2>&1 || true
    log_ok "Python tools"

    echo ""
    log_ok "FASE 5 COMPLETADA"
}

# =============================================================================
# FASE 6: DESPLIEGUE DE CONFIGURACIONES + APPS
# =============================================================================

fase_despliegue() {
    banner
    echo -e "  ${B}FASE 6/8: Despliegue COMPLETO en $REAL_HOME${RST}\n"

    # Estructura de directorios
    log_proc "Creando estructura de directorios..."
    mkdir -p "$CIBER_DIR"/{1_Scripts/{bash,python,generadores,go/netaudit,servicios},2_Laboratorios/{Redes/capturas,HTB,Network_Drive},3_Herramientas/{Escaneo,WiFi,Phishing,Movil,OSINT,Instaladores},4_Servicios/Conexiones_Servicios/{FTP,SSH,Unidades_Compartidas/{logs,credenciales,backups,montajes,configuracion},SMTP},5_Wordlists,6_Documentos,7_VPN/{HTB,TPLink}}
    mkdir -p "$MOSKOV_DIR"/{Apps/Update/logs,Fondo_Pantalla,Kiro}
    mkdir -p "$REAL_HOME"/{Documentos/OptimizacionEntorno/logs,.config/bin,.local/share/fonts}
    touch "$REAL_HOME/.config/bin/target"
    log_ok "Estructura creada"

    # Copiar scripts de ciberseguridad
    log_proc "Copiando scripts..."
    local SRC=""
    [[ -d "$REPO_DIR/scripts_estudio/1_Scripts" ]] && SRC="$REPO_DIR/scripts_estudio/1_Scripts"
    [[ -z "$SRC" && -d "$REPO_DIR/1_Scripts" ]] && SRC="$REPO_DIR/1_Scripts"
    if [[ -n "$SRC" ]]; then
        for sub in servicios python bash generadores go; do
            [[ -d "$SRC/$sub" ]] && cp -rf "$SRC/$sub/." "$CIBER_DIR/1_Scripts/$sub/" 2>/dev/null
        done
        log_ok "Scripts copiados"
    else
        log_err "Fuente de scripts no encontrada"
    fi

    # Desplegar Apps (scripts de instalacion de aplicaciones)
    log_proc "Desplegando carpeta Apps..."
    if [[ -d "$REPO_DIR/Apps" ]]; then
        cp -rf "$REPO_DIR/Apps/." "$MOSKOV_DIR/Apps/" 2>/dev/null
        find "$MOSKOV_DIR/Apps" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        log_ok "Apps desplegadas ($MOSKOV_DIR/Apps/)"
    fi

    # Desplegar configs WM
    log_proc "Desplegando configs -> ~/.config/..."
    local CFGS=(bspwm sxhkd polybar picom kitty rofi nvim neofetch)
    for cfg in "${CFGS[@]}"; do
        local S=""
        [[ -d "$REPO_DIR/$cfg/.config/$cfg" ]] && S="$REPO_DIR/$cfg/.config/$cfg"
        [[ -z "$S" && -d "$REPO_DIR/$cfg" ]] && S="$REPO_DIR/$cfg"
        if [[ -n "$S" && -d "$S" ]]; then
            rm -rf "$REAL_HOME/.config/$cfg"
            cp -r "$S" "$REAL_HOME/.config/$cfg"
            log_info "  -> $cfg"
        fi
    done
    log_ok "Configs desplegadas"

    # Wallpaper
    if [[ -f "$REPO_DIR/wallpaper/fondo.jpeg" ]]; then
        mkdir -p "$MOSKOV_DIR/Fondo_Pantalla"
        cp -f "$REPO_DIR/wallpaper/fondo.jpeg" "$MOSKOV_DIR/Fondo_Pantalla/fondo.jpeg"
        log_ok "Wallpaper desplegado"
    fi

    # Dotfiles
    [[ -f "$REPO_DIR/zshrc" ]] && cp -f "$REPO_DIR/zshrc" "$REAL_HOME/.zshrc" && \
        sed -i "s|\$(whoami)|$REAL_USER|g" "$REAL_HOME/.zshrc" && \
        log_ok ".zshrc (rutas expandidas para $REAL_USER)"
    [[ -f "$REPO_DIR/zsh/.p10k.zsh" ]] && cp -f "$REPO_DIR/zsh/.p10k.zsh" "$REAL_HOME/.p10k.zsh" && log_ok ".p10k.zsh"

    # Desplegar script de post-configuración en el escritorio
    if [[ -f "$REPO_DIR/post_config.sh" ]]; then
        cp -f "$REPO_DIR/post_config.sh" "$MOSKOV_DIR/post_config.sh"
        chmod +x "$MOSKOV_DIR/post_config.sh"
        log_ok "post_config.sh desplegado en $MOSKOV_DIR/"
    fi

    echo ""
    log_ok "FASE 6 COMPLETADA"
}

# =============================================================================
# FASE 7: PERMISOS, FUENTES Y PREVENCION DE REBOTE LOGIN
# =============================================================================

fase_permisos() {
    banner
    echo -e "  ${B}FASE 7/8: Permisos, fuentes y blindaje (IMPERATIVO)${RST}\n"

    log_proc "Permisos de ejecucion..."
    chmod +x "$REAL_HOME/.config/bspwm/bspwmrc" 2>/dev/null || true
    chmod +x "$REAL_HOME/.config/sxhkd/sxhkdrc" 2>/dev/null || true
    chmod +x "$REAL_HOME/.config/polybar/launch.sh" 2>/dev/null || true
    find "$REAL_HOME/.config/bspwm/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$REAL_HOME/.config/polybar/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$REAL_HOME/.config/sxhkd" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$CIBER_DIR/1_Scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$CIBER_DIR/1_Scripts" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    log_ok "Permisos aplicados"

    # Validar archivos criticos
    log_proc "Validando archivos criticos..."
    for f in "$REAL_HOME/.config/bspwm/bspwmrc" "$REAL_HOME/.config/sxhkd/sxhkdrc"; do
        if [[ ! -f "$f" ]]; then
            log_err "CRITICO FALTANTE: $f"
        elif [[ ! -x "$f" ]]; then
            chmod +x "$f"
            log_warn "Permisos corregidos: $f"
        else
            log_info "  OK: $f"
        fi
    done

    # Nerd Fonts
    local FONTS_DIR="$REAL_HOME/.local/share/fonts"
    mkdir -p "$FONTS_DIR"
    log_proc "Nerd Fonts..."
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip" -O /tmp/Hack.zip 2>/dev/null || true
    [[ -f /tmp/Hack.zip ]] && unzip -o /tmp/Hack.zip -d "$FONTS_DIR/" >> "$LOG_FILE" 2>&1 && rm -f /tmp/Hack.zip
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" -O /tmp/JBM.zip 2>/dev/null || true
    [[ -f /tmp/JBM.zip ]] && unzip -o /tmp/JBM.zip -d "$FONTS_DIR/" >> "$LOG_FILE" 2>&1 && rm -f /tmp/JBM.zip
    [[ -d "$REPO_DIR/polybar/.config/polybar/fonts" ]] && cp -f "$REPO_DIR/polybar/.config/polybar/fonts/"* "$FONTS_DIR/" 2>/dev/null || true
    fc-cache -fv >> "$LOG_FILE" 2>&1 || true
    log_ok "Fuentes instaladas"

    # Limpiar X11 residuales
    log_proc "Limpiando X11 residuales..."
    rm -f "$REAL_HOME/.Xauthority" "$REAL_HOME/.xsession-errors"* "$REAL_HOME/.ICEauthority"
    log_ok "X11 limpio"

    # CHOWN IMPERATIVO FINAL
    log_proc "chown -R $REAL_USER:$REAL_USER $REAL_HOME..."
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"
    if [[ $? -eq 0 ]]; then
        log_ok "Propiedad asignada a $REAL_USER"
    else
        log_err "ERROR en chown"
    fi

    # ─── P10k para root ─────────────────────────────────────────────────
    log_proc "Configurando P10k para root..."
    if [[ -f "$REAL_HOME/.p10k.zsh" ]]; then
        cp -f "$REAL_HOME/.p10k.zsh" /root/.p10k.zsh
    elif [[ -f "$REPO_DIR/zsh/.p10k.zsh" ]]; then
        cp -f "$REPO_DIR/zsh/.p10k.zsh" /root/.p10k.zsh
    fi
    [[ -d "$REAL_HOME/powerlevel10k" ]] && [[ ! -d /root/powerlevel10k ]] && \
        cp -r "$REAL_HOME/powerlevel10k" /root/powerlevel10k
    # .zshrc de root
    if [[ ! -f /root/.zshrc ]] || ! grep -q "powerlevel10k" /root/.zshrc 2>/dev/null; then
        cat > /root/.zshrc << 'ROOTZSH'
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /root/powerlevel10k/powerlevel10k.zsh-theme
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/zsh-sudo/sudo.plugin.zsh ] && source /usr/share/zsh-sudo/sudo.plugin.zsh

# Autocompletado case-insensitive
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'

# PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/usr/local/games:/usr/games"
if [ -d /opt ]; then
    for dir in $(find /opt -maxdepth 3 -type d -name "bin" 2>/dev/null); do
        export PATH="$dir:$PATH"
    done
fi

[[ ! -f /root/.p10k.zsh ]] || source /root/.p10k.zsh
ROOTZSH
    fi
    chsh -s /usr/bin/zsh root 2>/dev/null || true
    log_ok "P10k configurado para root"

    # ─── Scripts accesibles en PATH ──────────────────────────────────────
    # NOTA: Los scripts de servicios se acceden via aliases en .zshrc
    # (startftp, startssh, startfire, compartidos)
    # Limpiar symlinks previos que causan fork bomb por recursion
    rm -f "$REAL_HOME/.local/bin/gestionar_compartidos" 2>/dev/null
    rm -f "$REAL_HOME/.local/bin/startftp" 2>/dev/null
    rm -f "$REAL_HOME/.local/bin/startssh" 2>/dev/null
    rm -f "$REAL_HOME/.local/bin/startfire" 2>/dev/null
    rm -f "$REAL_HOME/.local/bin/open_ftp" 2>/dev/null
    log_ok "Scripts accesibles via aliases en .zshrc (sin symlinks)"

    echo ""
    log_ok "FASE 7 COMPLETADA"
}

# =============================================================================
# FASE 8: SHELL ZSH + FIREWALL + COMANDO UPDATE
# =============================================================================

fase_final() {
    banner
    echo -e "  ${B}FASE 8/8: Finalizacion${RST}\n"

    # zsh como shell
    local ZSH_PATH
    ZSH_PATH=$(which zsh 2>/dev/null || true)
    if [[ -n "$ZSH_PATH" ]]; then
        grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null || echo "$ZSH_PATH" >> /etc/shells
        chsh -s "$ZSH_PATH" "$REAL_USER" >> "$LOG_FILE" 2>&1 || true
        log_ok "Shell: zsh"
    else
        log_err "zsh no encontrado"
    fi

    # UFW
    log_proc "UFW..."
    ufw --force reset >> "$LOG_FILE" 2>&1 || true
    ufw default deny incoming >> "$LOG_FILE" 2>&1 || true
    ufw default allow outgoing >> "$LOG_FILE" 2>&1 || true
    ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1 || true
    ufw allow 7070/tcp comment 'AnyDesk' >> "$LOG_FILE" 2>&1 || true
    ufw allow 1194/udp comment 'OpenVPN' >> "$LOG_FILE" 2>&1 || true
    ufw allow 51820/udp comment 'WireGuard' >> "$LOG_FILE" 2>&1 || true
    ufw --force enable >> "$LOG_FILE" 2>&1 || true
    log_ok "UFW activo"

    # Comando update
    cat > /usr/local/bin/update <<'UPDATEEOF'
#!/bin/bash
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
[[ -z "$USER_HOME" ]] && USER_HOME="$HOME"
LOG_DIR="$USER_HOME/Desktop/$REAL_USER/Apps/Update/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"
{
    echo "========== [$(date)] INICIO =========="
    if command -v timeshift &>/dev/null; then
        sudo timeshift --create --comments "Pre-update" --tags D
    fi
    sudo parrot-upgrade -y 2>/dev/null || sudo apt-get upgrade -y
    echo "========== [$(date)] FIN =========="
} | tee -a "$LOG_FILE"
UPDATEEOF
    chmod +x /usr/local/bin/update
    log_ok "Comando update"

    systemctl enable lightdm >> "$LOG_FILE" 2>&1 || true
    log_ok "LightDM habilitado"

    echo ""
    log_ok "FASE 8 COMPLETADA"
}

# =============================================================================
# RESUMEN
# =============================================================================

resumen() {
    banner
    echo -e "  ${G}========================================================${RST}"
    echo -e "  ${G}       INSTALACION COMPLETADA - Moskov Env v3.0${RST}"
    echo -e "  ${G}========================================================${RST}\n"
    [[ $ERRORS -eq 0 ]] && echo -e "    ${G}[+] Sin errores${RST}" || echo -e "    ${Y}[!] $ERRORS advertencia(s)${RST}"
    echo ""
    echo -e "    Usuario:   ${C}$REAL_USER${RST}"
    echo -e "    Home:      ${C}$REAL_HOME${RST}"
    echo -e "    WM:        bspwm + polybar + picom + rofi"
    echo -e "    Terminal:  Kitty | Editor: Neovim"
    echo -e "    Shell:     zsh + P10k + fzf"
    echo -e "    Login:     LightDM -> BSPWM"
    echo -e "    Security:  metasploit, nmap, hydra, hashcat, sqlmap, wireshark..."
    echo -e "    Tools:     i3lock-fancy, impacket, pspy, evil-winrm, wpscan, ngrok"
    echo -e "    Apps:      $MOSKOV_DIR/Apps/"
    echo -e "    Scripts:   $CIBER_DIR/1_Scripts/"
    echo ""
    echo -e "    ${B}sudo reboot${RST} para iniciar con BSPWM"
    echo -e "    ${DIM}Log instalacion: $LOG_FILE${RST}"
    echo -e "    ${DIM}Log bspwm-session: $REAL_HOME/install_logs/bspwm-session.log${RST}\n"
}

# =============================================================================
# EJECUCION COMPLETA (usada por --auto y opcion 1)
# =============================================================================

ejecutar_instalacion_completa() {
    pre_limpieza
    fase_preflight
    fase_purga
    fase_paquetes || log_err "Fase paquetes con errores - continuando"
    fase_xsession || log_err "Fase xsession con errores - continuando"
    fase_binarios || log_err "Fase binarios con errores - continuando"
    fase_herramientas || log_err "Fase herramientas con errores - continuando"
    # OBLIGATORIAS: siempre se ejecutan
    fase_despliegue
    fase_permisos
    fase_final

    # VALIDACION PRE-REBOOT: Verificar que la sesion va a funcionar
    banner
    echo -e "  ${B}VALIDACION PRE-REBOOT${RST}\n"
    local FAIL=0

    # Verificar binario bspwm
    if command -v bspwm &>/dev/null; then
        log_ok "bspwm binario: $(which bspwm)"
    else
        log_err "bspwm NO encontrado en PATH"
        FAIL=1
    fi

    # Verificar bspwm-session
    if [[ -x /usr/bin/bspwm-session ]]; then
        log_ok "/usr/bin/bspwm-session ejecutable"
    else
        log_err "/usr/bin/bspwm-session NO existe o no es ejecutable"
        FAIL=1
    fi

    # Verificar bspwmrc
    if [[ -x "$REAL_HOME/.config/bspwm/bspwmrc" ]]; then
        log_ok "bspwmrc existe y es ejecutable"
    else
        log_err "bspwmrc falta o sin permisos"
        FAIL=1
    fi

    # Verificar sxhkdrc
    if [[ -f "$REAL_HOME/.config/sxhkd/sxhkdrc" ]]; then
        log_ok "sxhkdrc existe"
    else
        log_err "sxhkdrc NO existe"
        FAIL=1
    fi

    # Verificar .desktop
    if [[ -f /usr/share/xsessions/bspwm.desktop ]]; then
        log_ok "bspwm.desktop presente"
    else
        log_err "bspwm.desktop NO registrado"
        FAIL=1
    fi

    # Verificar propiedad de .config
    local OWNER=$(stat -c '%U' "$REAL_HOME/.config/bspwm/bspwmrc" 2>/dev/null)
    if [[ "$OWNER" == "$REAL_USER" ]]; then
        log_ok "Propiedad correcta: $REAL_USER"
    else
        log_err "Propiedad incorrecta: $OWNER (deberia ser $REAL_USER)"
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME"
        log_warn "chown aplicado de emergencia"
    fi

    # Verificar LightDM config
    if grep -q "user-session=bspwm" /etc/lightdm/lightdm.conf 2>/dev/null; then
        log_ok "LightDM apunta a sesion bspwm"
    else
        log_err "LightDM NO configurado para bspwm"
    fi

    echo ""
    if [[ $FAIL -eq 0 ]]; then
        log_ok "VALIDACION EXITOSA - Listo para reboot"
    else
        log_warn "Validacion con advertencias - revisar log"
    fi

    resumen
}

# =============================================================================
# MODO --auto: EJECUCION 100% DESATENDIDA
# =============================================================================

if [[ $AUTO_MODE -eq 1 ]]; then
    banner
    echo -e "  ${G}[AUTO] Instalacion COMPLETA desatendida iniciada${RST}\n"
    echo -e "  ${DIM}Usuario: $REAL_USER | Home: $REAL_HOME${RST}"
    echo -e "  ${DIM}GUI activa: $( [[ $GUI_ACTIVE -eq 1 ]] && echo 'SI (modo seguro)' || echo 'NO (TTY completo)' )${RST}\n"
    ejecutar_instalacion_completa
    echo ""
    echo -e "  ${G}[AUTO] Reiniciando en 5 segundos...${RST}"
    echo -e "  ${DIM}(Ctrl+C para cancelar reboot)${RST}"
    sleep 5
    reboot
fi

# =============================================================================
# MODOS INTERACTIVOS
# =============================================================================

instalacion_limpia() {
    echo -e "\n    ${R}[!] MODO DESTRUCTIVO: Eliminara entorno previo e instalara TODO.${RST}"
    [[ $GUI_ACTIVE -eq 1 ]] && echo -e "    ${Y}[~] GUI detectada: Xorg/LightDM no se reinstalaran${RST}"
    echo ""
    read -rp "    Confirmar? (s/n): " c
    [[ "$c" != "s" && "$c" != "S" ]] && return
    ejecutar_instalacion_completa
}

reinstalar_configs() {
    echo -e "\n    ${Y}[!] Sobrescribira dotfiles y configs.${RST}\n"
    read -rp "    Continuar? (s/n): " c
    [[ "$c" != "s" && "$c" != "S" ]] && return
    fase_despliegue
    fase_permisos
    resumen
}

actualizar_scripts() {
    banner
    echo -e "  ${B}Actualizar Scripts${RST}\n"
    local SRC=""
    [[ -d "$REPO_DIR/scripts_estudio/1_Scripts/servicios" ]] && SRC="$REPO_DIR/scripts_estudio/1_Scripts/servicios"
    [[ -z "$SRC" && -d "$REPO_DIR/1_Scripts/servicios" ]] && SRC="$REPO_DIR/1_Scripts/servicios"
    local DST="$CIBER_DIR/1_Scripts/servicios"
    mkdir -p "$DST"
    if [[ -n "$SRC" ]]; then
        cp -rf "$SRC/." "$DST/" 2>/dev/null
        find "$DST" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
        find "$DST" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
        chown -R "$REAL_USER:$REAL_USER" "$DST"
        log_ok "Scripts actualizados"
        ls "$DST/" 2>/dev/null | sed 's/^/      /'
    else
        log_err "Fuente no encontrada"
    fi
    echo ""
    read -rp "    ENTER para volver..." _
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

while true; do
    banner
    echo -e "  ${DIM}Usuario: $REAL_USER | Home: $REAL_HOME | Repo: $REPO_DIR${RST}"
    [[ $GUI_ACTIVE -eq 1 ]] && echo -e "  ${Y}[~] Sesion grafica ACTIVA (modo GUI-safe)${RST}" || echo -e "  ${G}[+] Modo TTY/CLI${RST}"
    echo ""
    echo -e "  ${G}1)${RST} Instalacion COMPLETA desde 0"
    echo -e "  ${G}2)${RST} Reinstalar / Restaurar Configs"
    echo -e "  ${G}3)${RST} Actualizar Scripts"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
    read -rp "  Opcion: " opt
    case $opt in
        1) instalacion_limpia ;;
        2) reinstalar_configs ;;
        3) actualizar_scripts ;;
        0) echo -e "\n    ${G}Hasta luego!${RST}\n"; exit 0 ;;
        *) echo -e "    ${R}[!] Invalido${RST}"; sleep 1 ;;
    esac
done
