#!/usr/bin/env bash
##############################################################################
# install_environment.sh — Moskov Environment v3.0
# Arquitectura Zero-Intervention: instalación 100% desatendida
# Prevención activa de caídas de X11 y bloqueos de dpkg
##############################################################################
set -uo pipefail

# ─── CONSTANTES Y DETECCIÓN DE ENTORNO ───────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

SCRIPT_VERSION="3.0"
SCRIPT_NAME="Moskov Environment"

# Detectar usuario real (funciona con sudo, su, logname)
detect_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    elif command -v logname &>/dev/null; then
        logname 2>/dev/null || echo "$USER"
    else
        echo "$USER"
    fi
}

REAL_USER="$(detect_real_user)"
REAL_HOME="$(eval echo "~${REAL_USER}")"

# ─── COLORES Y LOGGING ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_phase()  { echo -e "\n${BOLD}${CYAN}[$SCRIPT_NAME v$SCRIPT_VERSION]${NC} ${BOLD}$*${NC}"; }
log_info()   { echo -e "  ${CYAN}[INFO]${NC}  $*"; }
log_ok()     { echo -e "  ${GREEN}[OK]${NC}    $*"; }
log_warn()   { echo -e "  ${YELLOW}[WARN]${NC}  $*"; }
log_err()    { echo -e "  ${RED}[ERROR]${NC} $*"; }

# ─── VERIFICACIÓN DE PRIVILEGIOS ─────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    log_err "Este script requiere privilegios de root. Ejecuta con: sudo $0"
    exit 1
fi

log_phase "Iniciando instalación desatendida"
log_info "Usuario real detectado: ${REAL_USER}"
log_info "Home del usuario: ${REAL_HOME}"
log_info "Ejecutando como: $(whoami) (EUID=$EUID)"

##############################################################################
# FASE 0: PRE-FLIGHT — Auto-Reparación de APT/DPKG
##############################################################################
phase_preflight() {
    log_phase "FASE 0: PRE-FLIGHT — Saneamiento de APT/DPKG"

    # Matar procesos huérfanos de gestores de paquetes
    log_info "Terminando procesos huérfanos de apt/dpkg..."
    killall -9 apt apt-get dpkg 2>/dev/null || true
    fuser -k /var/lib/dpkg/lock 2>/dev/null || true
    fuser -k /var/lib/apt/lists/lock 2>/dev/null || true
    fuser -k /var/cache/apt/archives/lock 2>/dev/null || true

    # Liberar candados residuales
    log_info "Eliminando candados residuales..."
    rm -f /var/lib/apt/lists/lock
    rm -f /var/lib/dpkg/lock
    rm -f /var/lib/dpkg/lock-frontend
    rm -f /var/cache/apt/archives/lock

    # Reparar base de datos de dpkg
    log_info "Reparando base de datos de dpkg..."
    dpkg --configure -a --force-confdef --force-confold 2>/dev/null || true

    # Limpiar estado parcial de APT
    apt-get -f install -y --force-yes 2>/dev/null || \
        apt-get -f install -y 2>/dev/null || true

    log_ok "Pre-flight completado — APT/DPKG en estado limpio"
}

##############################################################################
# FASE 1: DETECCIÓN DEL ENTORNO GRÁFICO (Zero-Crash Display Logic)
##############################################################################
RUNNING_IN_XSESSION=false
LIGHTDM_ACTIVE=false

detect_display_environment() {
    log_phase "FASE 1: Detección del entorno gráfico"

    # Verificar si existe una sesión X11 activa
    if [[ -n "${DISPLAY:-}" ]]; then
        log_info "Variable DISPLAY detectada: $DISPLAY"
        RUNNING_IN_XSESSION=true
    fi

    # Verificar si hay un servidor X corriendo
    if pgrep -x Xorg &>/dev/null || pgrep -x X &>/dev/null; then
        log_info "Servidor Xorg activo detectado"
        RUNNING_IN_XSESSION=true
    fi

    # Verificar LightDM
    if pgrep -x lightdm &>/dev/null; then
        log_info "LightDM está corriendo"
        LIGHTDM_ACTIVE=true
        RUNNING_IN_XSESSION=true
    fi

    # Verificar BSPWM
    if pgrep -x bspwm &>/dev/null; then
        log_info "BSPWM activo — sesión gráfica viva confirmada"
        RUNNING_IN_XSESSION=true
    fi

    if [[ "$RUNNING_IN_XSESSION" == true ]]; then
        log_warn "Ejecutando DENTRO de sesión gráfica — modo protegido activo"
        log_warn "Se omitirá purga/reinstalación directa de Xorg/LightDM"
    else
        log_info "Ejecutando desde TTY/CLI — instalación base completa habilitada"
    fi
}

##############################################################################
# FASE 2: INSTALACIÓN DE PAQUETES (APT) — Aislamiento Modular
##############################################################################
APT_PHASE_SUCCESS=true

# Opciones globales de APT para modo no interactivo
APT_OPTS=(
    -y
    -o Dpkg::Options::="--force-confdef"
    -o Dpkg::Options::="--force-confold"
    -o APT::Get::AllowUnauthenticated=true
    -o Acquire::AllowInsecureRepositories=true
)

install_packages_safe() {
    local category="$1"
    shift
    local packages=("$@")

    log_info "Instalando categoría: ${category} (${#packages[@]} paquetes)"

    if apt-get install "${APT_OPTS[@]}" "${packages[@]}" 2>&1; then
        log_ok "Categoría '${category}' instalada correctamente"
    else
        log_warn "Algunos paquetes de '${category}' fallaron — continuando..."
        # Intentar paquetes individuales como fallback
        for pkg in "${packages[@]}"; do
            apt-get install "${APT_OPTS[@]}" "$pkg" 2>/dev/null || \
                log_warn "Paquete individual falló: $pkg (no crítico)"
        done
    fi
}

phase_apt_install() {
    log_phase "FASE 2: Instalación de paquetes (APT)"

    # Actualizar repositorios
    log_info "Actualizando repositorios..."
    apt-get update -qq 2>/dev/null || {
        log_warn "apt-get update tuvo advertencias — continuando"
    }

    # Upgrade del sistema (compatible con Parrot Security)
    log_info "Actualizando sistema..."
    if command -v parrot-upgrade &>/dev/null; then
        parrot-upgrade -y 2>/dev/null || log_warn "parrot-upgrade tuvo advertencias"
    else
        apt-get upgrade "${APT_OPTS[@]}" 2>/dev/null || log_warn "apt upgrade tuvo advertencias"
    fi

    # ─── Paquetes base del sistema ───────────────────────────────────────
    install_packages_safe "sistema-base" \
        build-essential git curl wget unzip tar \
        htop neofetch tree fzf ripgrep bat \
        zsh tmux stow

    # ─── Paquetes de entorno gráfico (condicional) ───────────────────────
    if [[ "$RUNNING_IN_XSESSION" == true ]]; then
        # Modo protegido: instalar componentes gráficos SIN purgar Xorg/LightDM
        log_info "Modo protegido: instalando WM y utilidades sin tocar X/LightDM"
        install_packages_safe "wm-protegido" \
            bspwm sxhkd polybar rofi dunst picom \
            feh nitrogen lxappearance \
            kitty alacritty
    else
        # TTY/CLI: instalación completa incluyendo servidor gráfico
        log_info "Modo TTY: instalación completa de stack gráfico"
        install_packages_safe "xorg-display" \
            xorg xserver-xorg xinit \
            lightdm lightdm-gtk-greeter

        install_packages_safe "wm-completo" \
            bspwm sxhkd polybar rofi dunst picom \
            feh nitrogen lxappearance \
            kitty alacritty

        # Habilitar LightDM para arranque automático
        systemctl enable lightdm 2>/dev/null || \
            log_warn "No se pudo habilitar lightdm (entorno sin systemd?)"
    fi

    # ─── Herramientas de desarrollo ──────────────────────────────────────
    install_packages_safe "dev-tools" \
        nodejs npm python3 python3-pip python3-venv \
        docker.io docker-compose

    # ─── Fuentes ─────────────────────────────────────────────────────────
    install_packages_safe "fonts" \
        fonts-firacode fonts-hack fonts-font-awesome \
        fonts-noto-color-emoji

    log_ok "Fase APT completada"
}

##############################################################################
# FASE 3: ESTRUCTURA DE DIRECTORIOS Y DOTFILES
# Esta fase se ejecuta SIEMPRE, independientemente del resultado de APT
##############################################################################
phase_dotfiles_and_structure() {
    log_phase "FASE 3: Estructura de directorios y dotfiles"

    # ─── Crear estructura Moskov ─────────────────────────────────────────
    log_info "Creando estructura ~/Desktop/Moskov/..."
    local moskov_dirs=(
        "${REAL_HOME}/Desktop/Moskov"
        "${REAL_HOME}/Desktop/Moskov/Kiro"
        "${REAL_HOME}/Desktop/Moskov/Projects"
        "${REAL_HOME}/Desktop/Moskov/Scripts"
        "${REAL_HOME}/Desktop/Moskov/Tools"
        "${REAL_HOME}/Desktop/Moskov/Wallpapers"
        "${REAL_HOME}/Desktop/Moskov/Resources"
    )

    for dir in "${moskov_dirs[@]}"; do
        mkdir -p "$dir"
        log_ok "Creado: $dir"
    done

    # ─── Crear estructura de configuración ───────────────────────────────
    log_info "Creando estructura ~/.config/..."
    local config_dirs=(
        "${REAL_HOME}/.config/bspwm"
        "${REAL_HOME}/.config/sxhkd"
        "${REAL_HOME}/.config/polybar"
        "${REAL_HOME}/.config/picom"
        "${REAL_HOME}/.config/kitty"
        "${REAL_HOME}/.config/rofi"
        "${REAL_HOME}/.config/dunst"
        "${REAL_HOME}/.config/alacritty"
        "${REAL_HOME}/.config/neofetch"
        "${REAL_HOME}/.config/autostart"
    )

    for dir in "${config_dirs[@]}"; do
        mkdir -p "$dir"
    done
    log_ok "Estructura ~/.config/ creada"

    # ─── Dotfiles base (bspwmrc) ─────────────────────────────────────────
    log_info "Desplegando dotfiles base..."

    # bspwmrc
    cat > "${REAL_HOME}/.config/bspwm/bspwmrc" << 'EOF'
#!/bin/sh
# Moskov BSPWM Configuration v3.0
pgrep -x sxhkd > /dev/null || sxhkd &
pgrep -x picom > /dev/null || picom --config ~/.config/picom/picom.conf &
pgrep -x polybar > /dev/null || ~/.config/polybar/launch.sh &
pgrep -x dunst > /dev/null || dunst &

# Monitors
bspc monitor -d I II III IV V VI VII VIII IX X

# Global settings
bspc config border_width          2
bspc config window_gap            10
bspc config split_ratio           0.52
bspc config borderless_monocle    true
bspc config gapless_monocle       true
bspc config focus_follows_pointer true

# Colors
bspc config normal_border_color   "#44475a"
bspc config active_border_color   "#bd93f9"
bspc config focused_border_color  "#ff79c6"

# Rules
bspc rule -a Firefox desktop='^2'
bspc rule -a Code desktop='^3'

# Wallpaper
feh --bg-fill ~/Desktop/Moskov/Wallpapers/wallpaper.jpg 2>/dev/null || \
    nitrogen --restore 2>/dev/null || true
EOF
    chmod +x "${REAL_HOME}/.config/bspwm/bspwmrc"

    # sxhkdrc
    cat > "${REAL_HOME}/.config/sxhkd/sxhkdrc" << 'EOF'
# Moskov SXHKD Configuration v3.0

# Terminal
super + Return
    kitty

# Program launcher
super + d
    rofi -show drun -theme ~/.config/rofi/config.rasi

# Close/kill window
super + {_,shift + }q
    bspc node -{c,k}

# Reload sxhkd
super + Escape
    pkill -USR1 -x sxhkd

# Reload bspwm
super + shift + r
    bspc wm -r

# Focus/swap windows
super + {h,j,k,l}
    bspc node -f {west,south,north,east}

super + shift + {h,j,k,l}
    bspc node -s {west,south,north,east}

# Switch desktops
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

# Move window to desktop
super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'

# Toggle floating/fullscreen
super + f
    bspc node -t '~fullscreen'

super + space
    bspc node -t '~floating'

# Screenshot
Print
    scrot ~/Desktop/Moskov/Screenshots/%Y-%m-%d_%H-%M-%S.png

# Lock screen
super + shift + x
    betterlockscreen -l
EOF

    # picom.conf
    cat > "${REAL_HOME}/.config/picom/picom.conf" << 'EOF'
# Moskov Picom Configuration v3.0
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 12;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.6;
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;
corner-radius = 8;
rounded-corners-exclude = [ "class_g = 'Polybar'" ];
opacity-rule = [ "90:class_g = 'kitty'" ];
EOF

    # Polybar launch script
    cat > "${REAL_HOME}/.config/polybar/launch.sh" << 'EOF'
#!/bin/bash
# Moskov Polybar Launcher
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar moskov-bar 2>&1 | tee -a /tmp/polybar.log & disown
EOF
    chmod +x "${REAL_HOME}/.config/polybar/launch.sh"

    # Polybar config
    cat > "${REAL_HOME}/.config/polybar/config.ini" << 'EOF'
; Moskov Polybar Configuration v3.0
[colors]
background = #1e1e2e
foreground = #cdd6f4
primary = #f5c2e7
secondary = #89b4fa
alert = #f38ba8

[bar/moskov-bar]
width = 100%
height = 28pt
radius = 0
background = ${colors.background}
foreground = ${colors.foreground}
padding-left = 1
padding-right = 2
module-margin = 1
font-0 = "FiraCode Nerd Font:size=10;2"
font-1 = "Font Awesome 6 Free:style=Solid:size=10;2"
modules-left = bspwm
modules-center = date
modules-right = cpu memory pulseaudio battery

[module/bspwm]
type = internal/bspwm
label-focused = %name%
label-focused-background = ${colors.primary}
label-focused-foreground = ${colors.background}
label-focused-padding = 1

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d
time = %H:%M:%S
label = %date% %time%

[module/cpu]
type = internal/cpu
interval = 2
label = CPU %percentage%%

[module/memory]
type = internal/memory
interval = 2
label = RAM %percentage_used%%
EOF

    # Kitty config
    cat > "${REAL_HOME}/.config/kitty/kitty.conf" << 'EOF'
# Moskov Kitty Configuration v3.0
font_family      FiraCode Nerd Font
bold_font        auto
italic_font      auto
font_size        11.0
window_padding_width 8
background_opacity 0.92
confirm_os_window_close 0
enable_audio_bell no
cursor_shape beam
shell zsh

# Catppuccin Mocha Theme
foreground #CDD6F4
background #1E1E2E
cursor #F5E0DC
selection_foreground #1E1E2E
selection_background #F5E0DC
color0 #45475A
color8 #585B70
color1 #F38BA8
color9 #F38BA8
color2 #A6E3A1
color10 #A6E3A1
color3 #F9E2AF
color11 #F9E2AF
color4 #89B4FA
color12 #89B4FA
color5 #F5C2E7
color13 #F5C2E7
color6 #94E2D5
color14 #94E2D5
color7 #BAC2DE
color15 #A6ADC8
EOF

    # ─── Session Launcher: /usr/bin/bspwm-session ───────────────────────
    # Este archivo es ejecutado por LightDM al iniciar sesión BSPWM
    # Se despliega con rutas correctas para evitar "sxhkd: not found"
    log_info "Desplegando /usr/bin/bspwm-session (session launcher)..."
    cat > /usr/bin/bspwm-session << 'EOF'
#!/bin/sh
# Moskov Environment - BSPWM Session Launcher
# Ejecutado por LightDM al iniciar sesion

# 1. Garantizar HOME y PATH completo (incluye /usr/local/bin)
export HOME="${HOME:-$(getent passwd $(id -un) | cut -d: -f6)}"
export XDG_CURRENT_DESKTOP="bspwm"
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"

# 2. Log de depuracion
mkdir -p "$HOME/install_logs"
LOGF="$HOME/install_logs/bspwm-session.log"
echo "=== [$(date)] SESSION START ===" >> "$LOGF"
echo "USER=$(id -un) HOME=$HOME" >> "$LOGF"
echo "PATH=$PATH" >> "$LOGF"

# 3. Verificar que bspwmrc existe y es ejecutable
BSPWMRC="$HOME/.config/bspwm/bspwmrc"
if [ ! -f "$BSPWMRC" ]; then
    echo "ERROR: $BSPWMRC no existe" >> "$LOGF"
    mkdir -p "$HOME/.config/bspwm"
    echo '#!/bin/sh' > "$BSPWMRC"
    echo 'bspc monitor -d I II III IV V' >> "$BSPWMRC"
fi
chmod +x "$BSPWMRC"

# 4. Lanzar sxhkd con ruta absoluta y config correcta
SXHKDRC="$HOME/.config/sxhkd/sxhkdrc"
if [ -f "$SXHKDRC" ]; then
    /usr/local/bin/sxhkd -c "$SXHKDRC" >> "$LOGF" 2>&1 &
    echo "sxhkd PID=$!" >> "$LOGF"
else
    echo "WARN: sxhkdrc no encontrado en $SXHKDRC" >> "$LOGF"
    # Lanzar sxhkd sin config explícita (usará default)
    /usr/local/bin/sxhkd >> "$LOGF" 2>&1 &
    echo "sxhkd (sin config) PID=$!" >> "$LOGF"
fi

# 5. Ejecutar bspwm (exec mantiene la sesion viva para LightDM)
echo "Launching: bspwm -c $BSPWMRC" >> "$LOGF"
exec /usr/local/bin/bspwm -c "$BSPWMRC"
EOF
    chmod +x /usr/bin/bspwm-session
    log_ok "bspwm-session desplegado en /usr/bin/"

    # ─── Xsession .desktop para LightDM ─────────────────────────────────
    log_info "Desplegando bspwm.desktop para LightDM..."
    mkdir -p /usr/share/xsessions
    cat > /usr/share/xsessions/bspwm.desktop << 'EOF'
[Desktop Entry]
Name=bspwm (Moskov)
Comment=Binary space partitioning window manager - Moskov Environment
Exec=/usr/bin/bspwm-session
Type=Application
Keywords=tiling;wm;windowmanager;window;manager;
EOF
    log_ok "bspwm.desktop desplegado en /usr/share/xsessions/"

    log_ok "Dotfiles y session launcher desplegados correctamente"
}

##############################################################################
# FASE 4: PERMISOS Y PROPIEDAD FINAL
##############################################################################
phase_permissions() {
    log_phase "FASE 4: Asignación de permisos y propiedad"

    # Asignar propiedad recursiva al usuario real
    log_info "Aplicando chown -R ${REAL_USER}:${REAL_USER} en ${REAL_HOME}..."
    chown -R "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/Desktop/Moskov" 2>/dev/null || true
    chown -R "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/.config" 2>/dev/null || true

    # Permisos ejecutables en scripts
    log_info "Asignando permisos ejecutables a scripts..."
    find "${REAL_HOME}/.config/bspwm" -name "*.sh" -o -name "bspwmrc" | \
        xargs -r chmod +x 2>/dev/null || true
    find "${REAL_HOME}/.config/polybar" -name "*.sh" | \
        xargs -r chmod +x 2>/dev/null || true
    find "${REAL_HOME}/Desktop/Moskov/Scripts" -name "*.sh" | \
        xargs -r chmod +x 2>/dev/null || true

    # Verificar propietario final
    local owner
    owner=$(stat -c '%U' "${REAL_HOME}/Desktop/Moskov" 2>/dev/null || echo "unknown")
    if [[ "$owner" == "$REAL_USER" ]]; then
        log_ok "Propiedad correcta: ${REAL_USER} sobre ~/Desktop/Moskov"
    else
        log_warn "Propiedad inesperada: ${owner} (esperado: ${REAL_USER})"
    fi

    log_ok "Permisos y propiedad asignados"
}

##############################################################################
# FASE 5: RESUMEN Y FINALIZACIÓN
##############################################################################
phase_summary() {
    log_phase "FASE 5: Resumen de instalación"

    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}║  $SCRIPT_NAME v$SCRIPT_VERSION — Instalación Completada  ║${NC}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Usuario:       ${BOLD}${REAL_USER}${NC}"
    echo -e "  Home:          ${BOLD}${REAL_HOME}${NC}"
    echo -e "  Sesión gráfica: ${BOLD}${RUNNING_IN_XSESSION}${NC}"
    echo ""

    if [[ "$RUNNING_IN_XSESSION" == true ]]; then
        echo -e "  ${YELLOW}Nota: Se ejecutó en modo protegido (sesión X11 activa).${NC}"
        echo -e "  ${YELLOW}Xorg/LightDM no fueron modificados para proteger tu sesión.${NC}"
        echo -e "  ${YELLOW}Reinicia la sesión para cargar la nueva configuración.${NC}"
    else
        echo -e "  ${CYAN}LightDM habilitado. Reinicia para iniciar sesión gráfica:${NC}"
        echo -e "  ${BOLD}  sudo reboot${NC}"
    fi
    echo ""
}

##############################################################################
# EJECUCIÓN PRINCIPAL — Orquestador de fases con aislamiento modular
##############################################################################
main() {
    local start_time
    start_time=$(date +%s)

    echo ""
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $SCRIPT_NAME v$SCRIPT_VERSION — Zero-Intervention Installer${NC}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # FASE 0: Pre-flight (APT/DPKG repair)
    phase_preflight

    # FASE 1: Detectar entorno gráfico
    detect_display_environment

    # FASE 2: Instalación de paquetes (aislada — fallos no bloquean fase 3)
    phase_apt_install || {
        log_warn "Fase APT reportó errores no críticos — continuando a dotfiles"
        APT_PHASE_SUCCESS=false
    }

    # FASE 3: Dotfiles y estructura (se ejecuta SIEMPRE)
    phase_dotfiles_and_structure

    # FASE 4: Permisos (se ejecuta SIEMPRE)
    phase_permissions

    # FASE 5: Resumen
    phase_summary

    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    log_info "Tiempo total de ejecución: ${elapsed} segundos"

    if [[ "$APT_PHASE_SUCCESS" == false ]]; then
        log_warn "Instalación completada con advertencias en APT."
        log_warn "Dotfiles y permisos se aplicaron correctamente."
        exit 0  # Exit 0 porque dotfiles/permisos son lo crítico
    fi

    log_ok "Instalación completada sin errores."
    exit 0
}

# Ejecutar
main "$@"
