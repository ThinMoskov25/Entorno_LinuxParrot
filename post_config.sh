#!/bin/bash
# =============================================================================
# post_config.sh — Configuración Post-Instalación
# Se despliega en: ~/Desktop/$USER/post_config.sh
# Uso: bash ~/Desktop/$USER/post_config.sh
# =============================================================================
set -uo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
B='\033[1m'
NC='\033[0m'

# ─── Detección de usuario y rutas ────────────────────────────────────────────
CURRENT_USER="$(whoami)"
USER_HOME="$HOME"
USER_DIR="$USER_HOME/Desktop/$CURRENT_USER"
APPS_DIR="$USER_DIR/Apps"
CIBER_DIR="$USER_DIR/Ciberseguridad"
SCRIPTS_DIR="$CIBER_DIR/1_Scripts"

# ─── Funciones ───────────────────────────────────────────────────────────────
banner() {
    clear
    echo -e "${C}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║        POST-CONFIGURACIÓN — $CURRENT_USER               ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

pause() {
    echo ""
    echo -e "  ${Y}Presiona Enter para continuar...${NC}"
    read -r
}

# =============================================================================
# OPCIÓN 1: Powerlevel10k
# =============================================================================
menu_p10k() {
    banner
    echo -e "  ${B}POWERLEVEL10K${NC}\n"
    echo -e "  ${G}1)${NC} Configurar P10k desde cero (wizard interactivo)"
    echo -e "  ${G}2)${NC} Replicar configuración del repo (copiar .p10k.zsh)"
    echo -e "  ${G}3)${NC} Replicar P10k en root"
    echo -e "  ${G}0)${NC} Volver"
    echo ""
    read -rp "  Opción: " opt

    case $opt in
        1)
            echo -e "\n  ${C}Lanzando wizard de P10k...${NC}\n"
            zsh -ic "p10k configure"
            echo -e "\n  ${G}[+] Configuración guardada en ~/.p10k.zsh${NC}"
            pause
            ;;
        2)
            # Buscar .p10k.zsh en el repo clonado
            local P10K_SRC=""
            [[ -f "/tmp/entorno/zsh/.p10k.zsh" ]] && P10K_SRC="/tmp/entorno/zsh/.p10k.zsh"
            [[ -z "$P10K_SRC" && -f "$USER_DIR/.p10k.zsh" ]] && P10K_SRC="$USER_DIR/.p10k.zsh"
            [[ -z "$P10K_SRC" && -f "$USER_HOME/.p10k.zsh" ]] && P10K_SRC="$USER_HOME/.p10k.zsh"

            if [[ -n "$P10K_SRC" ]]; then
                cp -f "$P10K_SRC" "$USER_HOME/.p10k.zsh"
                echo -e "  ${G}[+] .p10k.zsh copiado desde: $P10K_SRC${NC}"
            else
                echo -e "  ${R}[!] No se encontró .p10k.zsh en el repo${NC}"
                echo -e "  ${Y}    Ejecuta opción 1 para configurar desde cero${NC}"
            fi
            pause
            ;;
        3)
            config_p10k_root
            pause
            ;;
        0) return ;;
    esac
}

# =============================================================================
# OPCIÓN 3: Replicar P10k en root
# =============================================================================
config_p10k_root() {
    echo -e "\n  ${C}Replicando P10k en root...${NC}"

    if [[ ! -f "$USER_HOME/.p10k.zsh" ]]; then
        echo -e "  ${R}[!] Primero configura P10k para tu usuario (opción 1 o 2)${NC}"
        return
    fi

    # Copiar .p10k.zsh a root
    sudo cp -f "$USER_HOME/.p10k.zsh" /root/.p10k.zsh
    echo -e "  ${G}[+] .p10k.zsh copiado a /root/${NC}"

    # Copiar powerlevel10k a root si no existe
    if [[ ! -d /root/powerlevel10k ]]; then
        sudo cp -r "$USER_HOME/powerlevel10k" /root/powerlevel10k
        echo -e "  ${G}[+] powerlevel10k copiado a /root/${NC}"
    fi

    # Configurar .zshrc de root
    if [[ ! -f /root/.zshrc ]] || ! grep -q "powerlevel10k" /root/.zshrc 2>/dev/null; then
        sudo tee /root/.zshrc > /dev/null << 'ROOTZSH'
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /root/powerlevel10k/powerlevel10k.zsh-theme

# Plugins
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/zsh-sudo/sudo.plugin.zsh ] && source /usr/share/zsh-sudo/sudo.plugin.zsh

# P10k config
[[ ! -f /root/.p10k.zsh ]] || source /root/.p10k.zsh
ROOTZSH
        echo -e "  ${G}[+] .zshrc de root configurado${NC}"
    else
        echo -e "  ${Y}[~] .zshrc de root ya tiene powerlevel10k${NC}"
    fi

    # Asegurar que root use zsh
    sudo chsh -s /usr/bin/zsh root 2>/dev/null || true
    echo -e "  ${G}[+] Shell de root cambiado a zsh${NC}"
    echo -e "\n  ${G}Listo. Al hacer 'sudo su' o 'sudo -i' verás P10k.${NC}"
}

# =============================================================================
# OPCIÓN 2: Instalar Apps
# =============================================================================
menu_apps() {
    banner
    echo -e "  ${B}INSTALADOR DE APPS${NC}"
    echo -e "  ${C}Directorio: $APPS_DIR${NC}\n"

    if [[ ! -d "$APPS_DIR" ]]; then
        echo -e "  ${R}[!] No se encontró $APPS_DIR${NC}"
        pause
        return
    fi

    # Listar apps disponibles
    local apps=()
    local i=1
    for dir in "$APPS_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        local name=$(basename "$dir")
        [[ "$name" == "Update" ]] && continue
        apps+=("$dir")
        echo -e "  ${G}$i)${NC} $name"
        ((i++))
    done

    echo ""
    echo -e "  ${G}A)${NC} Instalar TODAS"
    echo -e "  ${G}0)${NC} Volver"
    echo ""
    read -rp "  Opción (número o A): " opt

    if [[ "$opt" == "A" || "$opt" == "a" ]]; then
        echo -e "\n  ${C}Instalando todas las apps...${NC}\n"
        for app_dir in "${apps[@]}"; do
            install_app "$app_dir"
        done
        pause
    elif [[ "$opt" =~ ^[0-9]+$ ]] && (( opt >= 1 && opt < i )); then
        install_app "${apps[$((opt-1))]}"
        pause
    fi
}

install_app() {
    local app_dir="$1"
    local name=$(basename "$app_dir")
    local script=""

    # Buscar script de instalación
    script=$(find "$app_dir" -maxdepth 1 -name "*.sh" -type f | head -1)

    if [[ -n "$script" ]]; then
        echo -e "  ${Y}[*] Instalando: $name${NC}"
        chmod +x "$script"
        sudo bash "$script" 2>&1 | tail -5
        echo -e "  ${G}[+] $name completado${NC}\n"
    else
        echo -e "  ${Y}[~] $name: sin script .sh encontrado${NC}"
    fi
}

# =============================================================================
# OPCIÓN 3: Configuración de Red
# =============================================================================
menu_red() {
    banner
    echo -e "  ${B}CONFIGURACIÓN DE RED${NC}\n"

    # Detectar interfaces
    local ifaces=()
    local ips=()
    for iface in $(ls /sys/class/net/ | grep -v lo | sort); do
        ifaces+=("$iface")
        local ip=$(ip -4 addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        [[ -z "$ip" ]] && ip="Sin IP"
        ips+=("$ip")
    done

    echo -e "  ${C}Interfaces detectadas:${NC}\n"
    for i in "${!ifaces[@]}"; do
        local status="${G}●${NC}"
        [[ "${ips[$i]}" == "Sin IP" ]] && status="${R}○${NC}"
        echo -e "  $status ${B}${ifaces[$i]}${NC} — ${ips[$i]}"
    done

    echo ""
    echo -e "  ${B}Configuración de Polybar:${NC}"

    # Interfaz principal (primera con IP)
    local primary=""
    local secondary=""
    for i in "${!ifaces[@]}"; do
        if [[ "${ips[$i]}" != "Sin IP" && -z "$primary" ]]; then
            primary="${ifaces[$i]}"
        elif [[ -z "$secondary" ]]; then
            secondary="${ifaces[$i]}"
        fi
    done

    echo -e "  Primaria:   ${G}${primary:-Ninguna}${NC}"
    if [[ -n "$secondary" ]]; then
        echo -e "  Secundaria: ${Y}${secondary} (${ips[1]:-Sin IP})${NC}"
    else
        echo -e "  Secundaria: ${R}No configurada${NC}"
    fi

    echo ""
    echo -e "  ${G}1)${NC} Configurar interfaz primaria manualmente"
    echo -e "  ${G}2)${NC} Reiniciar NetworkManager"
    echo -e "  ${G}3)${NC} Solicitar IP por DHCP en todas las interfaces"
    echo -e "  ${G}0)${NC} Volver"
    echo ""
    read -rp "  Opción: " opt

    case $opt in
        1)
            echo -e "\n  Interfaces disponibles:"
            for i in "${!ifaces[@]}"; do
                echo -e "    $((i+1))) ${ifaces[$i]}"
            done
            read -rp "  Selecciona interfaz: " sel
            if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#ifaces[@]} )); then
                local selected="${ifaces[$((sel-1))]}"
                echo -e "  ${Y}Solicitando IP para $selected...${NC}"
                sudo dhclient "$selected" 2>/dev/null || sudo dhcpcd "$selected" 2>/dev/null || \
                    sudo ip link set "$selected" up
                sleep 2
                local new_ip=$(ip -4 addr show "$selected" 2>/dev/null | grep "inet " | awk '{print $2}')
                echo -e "  ${G}[+] $selected: ${new_ip:-Sin IP aún}${NC}"
            fi
            pause
            ;;
        2)
            echo -e "  ${Y}Reiniciando NetworkManager...${NC}"
            sudo systemctl restart NetworkManager 2>/dev/null || sudo service NetworkManager restart 2>/dev/null
            sleep 3
            echo -e "  ${G}[+] NetworkManager reiniciado${NC}"
            pause
            ;;
        3)
            for iface in "${ifaces[@]}"; do
                echo -e "  ${Y}DHCP en $iface...${NC}"
                sudo dhclient "$iface" 2>/dev/null &
            done
            sleep 3
            echo -e "  ${G}[+] DHCP solicitado en todas las interfaces${NC}"
            pause
            ;;
        0) return ;;
    esac
}

# =============================================================================
# OPCIÓN 4: Validar Scripts y Funciones
# =============================================================================
menu_validar() {
    banner
    echo -e "  ${B}VALIDACIÓN DE SCRIPTS Y FUNCIONES${NC}\n"

    local total=0
    local ok=0
    local fail=0
    local fails=()

    # Verificar scripts en Ciberseguridad
    echo -e "  ${C}── Scripts en $SCRIPTS_DIR ──${NC}\n"
    if [[ -d "$SCRIPTS_DIR" ]]; then
        while IFS= read -r script; do
            ((total++))
            local name=$(basename "$script")
            if [[ -x "$script" ]]; then
                # Verificar sintaxis
                if bash -n "$script" 2>/dev/null || python3 -c "import py_compile; py_compile.compile('$script', doraise=True)" 2>/dev/null; then
                    echo -e "  ${G}✓${NC} $name"
                    ((ok++))
                else
                    echo -e "  ${R}✗${NC} $name (error de sintaxis)"
                    ((fail++))
                    fails+=("$name: error sintaxis")
                fi
            else
                echo -e "  ${Y}⚠${NC} $name (sin permiso +x)"
                chmod +x "$script"
                echo -e "    ${G}→ Permiso corregido${NC}"
                ((ok++))
            fi
        done < <(find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null)
    else
        echo -e "  ${R}[!] $SCRIPTS_DIR no existe${NC}"
    fi

    # Verificar scripts en bspwm
    echo -e "\n  ${C}── Scripts en ~/.config/bspwm/scripts/ ──${NC}\n"
    if [[ -d "$USER_HOME/.config/bspwm/scripts" ]]; then
        while IFS= read -r script; do
            ((total++))
            local name=$(basename "$script")
            if [[ -x "$script" ]]; then
                if bash -n "$script" 2>/dev/null || python3 -c "import py_compile; py_compile.compile('$script', doraise=True)" 2>/dev/null; then
                    echo -e "  ${G}✓${NC} $name"
                    ((ok++))
                else
                    echo -e "  ${R}✗${NC} $name (error de sintaxis)"
                    ((fail++))
                    fails+=("$name: error sintaxis")
                fi
            else
                echo -e "  ${Y}⚠${NC} $name (sin permiso +x)"
                chmod +x "$script"
                echo -e "    ${G}→ Permiso corregido${NC}"
                ((ok++))
            fi
        done < <(find "$USER_HOME/.config/bspwm/scripts" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null)
    fi

    # Verificar que comandos PATH funcionen
    echo -e "\n  ${C}── Comandos en PATH ──${NC}\n"
    local cmds=(bspwm sxhkd polybar picom rofi kitty nvim zsh fzf bat)
    for cmd in "${cmds[@]}"; do
        ((total++))
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${G}✓${NC} $cmd ($(command -v "$cmd"))"
            ((ok++))
        else
            echo -e "  ${R}✗${NC} $cmd — NO ENCONTRADO"
            ((fail++))
            fails+=("$cmd: no instalado")
        fi
    done

    # Verificar scripts de servicios accesibles
    echo -e "\n  ${C}── Accesibilidad de scripts de servicios ──${NC}\n"
    if [[ -d "$SCRIPTS_DIR/servicios" ]]; then
        while IFS= read -r script; do
            ((total++))
            local name=$(basename "$script")
            if [[ -x "$script" ]]; then
                echo -e "  ${G}✓${NC} $name → ejecutable"
                ((ok++))
            else
                echo -e "  ${R}✗${NC} $name → sin +x"
                chmod +x "$script"
                echo -e "    ${G}→ Corregido${NC}"
                ((ok++))
            fi
        done < <(find "$SCRIPTS_DIR/servicios" -type f -name "*.sh" 2>/dev/null)
    fi

    # Resumen
    echo -e "\n  ══════════════════════════════════════"
    echo -e "  ${B}Resumen:${NC} Total=$total  ${G}OK=$ok${NC}  ${R}Fallos=$fail${NC}"
    if [[ $fail -gt 0 ]]; then
        echo -e "\n  ${R}Problemas:${NC}"
        for f in "${fails[@]}"; do
            echo -e "    - $f"
        done
    fi
    echo ""

    # Ofrecer agregar scripts al PATH
    if [[ -d "$SCRIPTS_DIR/servicios" ]]; then
        echo -e "  ${Y}¿Agregar scripts de servicios al PATH? (s/n)${NC}"
        read -rp "  > " ans
        if [[ "$ans" == "s" || "$ans" == "S" ]]; then
            # Crear symlinks en ~/.local/bin
            mkdir -p "$USER_HOME/.local/bin"
            for script in "$SCRIPTS_DIR/servicios/"*.sh; do
                [[ -f "$script" ]] || continue
                local name=$(basename "$script" .sh)
                ln -sf "$script" "$USER_HOME/.local/bin/$name"
            done
            # Asegurar que ~/.local/bin esté en PATH
            if ! grep -q "\.local/bin" "$USER_HOME/.zshrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.zshrc"
            fi
            echo -e "  ${G}[+] Scripts enlazados en ~/.local/bin/${NC}"
            echo -e "  ${G}    Ahora puedes ejecutar: gestionar_compartidos, startftp, etc.${NC}"
        fi
    fi

    pause
}

# =============================================================================
# MENÚ PRINCIPAL
# =============================================================================
main_menu() {
    while true; do
        banner
        echo -e "  ${G}1)${NC} Powerlevel10k (configurar / replicar / root)"
        echo -e "  ${G}2)${NC} Instalar Apps (~/Desktop/$CURRENT_USER/Apps/)"
        echo -e "  ${G}3)${NC} Configuración de Red"
        echo -e "  ${G}4)${NC} Validar scripts y funciones"
        echo -e ""
        echo -e "  ${R}0)${NC} Salir"
        echo ""
        read -rp "  Opción: " choice

        case $choice in
            1) menu_p10k ;;
            2) menu_apps ;;
            3) menu_red ;;
            4) menu_validar ;;
            0) echo -e "\n  ${G}Hasta luego.${NC}\n"; exit 0 ;;
            *) echo -e "  ${R}Opción inválida${NC}"; sleep 1 ;;
        esac
    done
}

# Ejecutar
main_menu
