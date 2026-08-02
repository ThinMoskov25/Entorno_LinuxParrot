#!/bin/bash
# =============================================================================
# post_config.sh - Configuracion Post-Instalacion v1.0
# Autor: Moskov | TUI ANSI Estatica
# Uso: bash post_config.sh
# =============================================================================

# ─── TERMINAL ────────────────────────────────────────────────────────────────
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == "xterm-kitty" ]] && export TERM="xterm-256color"

# ─── COLORES ─────────────────────────────────────────────────────────────────
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# ─── DETECCION DE USUARIO Y RUTAS ────────────────────────────────────────────
CURRENT_USER="$(whoami)"
USER_HOME="$HOME"
USER_DIR="$USER_HOME/Desktop/$CURRENT_USER"
APPS_DIR="$USER_DIR/Apps"
CIBER_DIR="$USER_DIR/Ciberseguridad"
SCRIPTS_DIR="$CIBER_DIR/1_Scripts"
RESULTADO=""

# ─── UTILIDADES ──────────────────────────────────────────────────────────────
limpiar() { printf '\033[H\033[J'; }

dibujar_cabecera() {
    echo -e "${C}  ══════════════════════════════════════════════════════════${RST}"
    echo -e "${C}         CONFIGURACION POST-INSTALACION - $CURRENT_USER${RST}"
    echo -e "${C}  ══════════════════════════════════════════════════════════${RST}"
    echo -e "  ${DIM}User: $CURRENT_USER | Home: $USER_HOME | Dir: $USER_DIR${RST}"
    echo -e "${C}  ──────────────────────────────────────────────────────────${RST}"
}

dibujar_menu() {
    echo ""
    echo -e "  ${G}1)${RST} Powerlevel10k"
    echo -e "  ${G}2)${RST} Instalar Apps"
    echo -e "  ${G}3)${RST} Configuracion de Red"
    echo -e "  ${G}4)${RST} Validar Scripts y Funciones"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
}

dibujar_resultado() {
    if [[ -n "$RESULTADO" ]]; then
        echo -e "${C}  ─── Resultado ───────────────────────────────────────────${RST}"
        echo -e "$RESULTADO"
        echo -e "${C}  ─────────────────────────────────────────────────────────${RST}"
    fi
}

redibujar() { limpiar; dibujar_cabecera; dibujar_menu; dibujar_resultado; }

# =============================================================================
# 1. POWERLEVEL10K
# =============================================================================
menu_p10k() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Powerlevel10k ──${RST}\n"
        echo -e "  ${G}1)${RST} Configurar desde cero (wizard)"
        echo -e "  ${G}2)${RST} Replicar configuracion del repo"
        echo -e "  ${G}3)${RST} Replicar en root"
        echo -e "  ${G}0)${RST} Volver"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " opt
        RESULTADO=""
        case $opt in
            1) p10k_wizard ;;
            2) p10k_replicar ;;
            3) p10k_root ;;
            0) return ;;
            *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
        esac
    done
}

p10k_wizard() {
    # Corregir error linea 77 antes de lanzar
    if grep -q '/opt/\*/\*/bin' "$USER_HOME/.zshrc" 2>/dev/null; then
        sed -i 's|for dir in /opt/\*/bin /opt/\*/\*/bin;|for dir in /opt/*/bin /opt/*/*/bin(N);|' "$USER_HOME/.zshrc" 2>/dev/null
    fi
    zsh -ic "p10k configure"
    [[ -f "$USER_HOME/.p10k.zsh" ]] && RESULTADO="  ${G}[+]${RST} P10k configurado correctamente" || RESULTADO="  ${R}[!]${RST} No se genero .p10k.zsh"
}

p10k_replicar() {
    local src=""
    [[ -f "/tmp/entorno/zsh/.p10k.zsh" ]] && src="/tmp/entorno/zsh/.p10k.zsh"
    [[ -z "$src" ]] && src=$(find "$USER_DIR" "$USER_HOME" -maxdepth 2 -name ".p10k.zsh" 2>/dev/null | head -1)

    if [[ -n "$src" ]]; then
        cp -f "$src" "$USER_HOME/.p10k.zsh"
        # Corregir error linea 77
        if grep -q '/opt/\*/\*/bin' "$USER_HOME/.zshrc" 2>/dev/null; then
            sed -i 's|for dir in /opt/\*/bin /opt/\*/\*/bin;|for dir in /opt/*/bin /opt/*/*/bin(N);|' "$USER_HOME/.zshrc" 2>/dev/null
        fi
        RESULTADO="  ${G}[+]${RST} .p10k.zsh copiado desde: $src\n  ${DIM}Reinicia terminal para ver cambios${RST}"
    else
        RESULTADO="  ${R}[!]${RST} No se encontro .p10k.zsh\n  ${DIM}Usa opcion 1 para configurar desde cero${RST}"
    fi
}

p10k_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        RESULTADO="  ${R}[!]${RST} Requiere root: sudo bash post_config.sh"
        return
    fi

    local src="$USER_HOME/.p10k.zsh"
    [[ ! -f "$src" ]] && src="/tmp/entorno/zsh/.p10k.zsh"
    if [[ ! -f "$src" ]]; then
        RESULTADO="  ${R}[!]${RST} Primero configura P10k (opcion 1 o 2)"
        return
    fi

    cp -f "$src" /root/.p10k.zsh
    [[ -d "$USER_HOME/powerlevel10k" && ! -d /root/powerlevel10k ]] && \
        cp -r "$USER_HOME/powerlevel10k" /root/powerlevel10k

    cat > /root/.zshrc << 'ROOTZSH'
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /root/powerlevel10k/powerlevel10k.zsh-theme
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/zsh-sudo/sudo.plugin.zsh ] && source /usr/share/zsh-sudo/sudo.plugin.zsh
[[ ! -f /root/.p10k.zsh ]] || source /root/.p10k.zsh
ROOTZSH

    chsh -s /usr/bin/zsh root 2>/dev/null
    RESULTADO="  ${G}[+]${RST} P10k replicado en root\n  ${G}[+]${RST} Shell root: zsh\n  ${DIM}sudo su para verificar${RST}"
}

# =============================================================================
# 2. INSTALAR APPS
# =============================================================================
menu_apps() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Instalar Apps ──${RST}"
        echo -e "  ${DIM}Directorio: $APPS_DIR${RST}\n"

        if [[ ! -d "$APPS_DIR" ]]; then
            RESULTADO="  ${R}[!]${RST} No se encontro: $APPS_DIR"
            dibujar_resultado; read -rp "  Enter para volver..."; return
        fi

        local apps=() names=()
        local i=1
        for dir in "$APPS_DIR"/*/; do
            [[ -d "$dir" ]] || continue
            local name=$(basename "$dir")
            [[ "$name" == "Update" || "$name" == "logs" ]] && continue
            local script=$(find "$dir" -maxdepth 1 -name "*.sh" -type f | head -1)
            [[ -z "$script" ]] && continue
            apps+=("$script")
            names+=("$name")
            echo -e "  ${G}$i)${RST} $name"
            ((i++))
        done

        echo ""
        echo -e "  ${G}A)${RST} Instalar TODAS"
        echo -e "  ${G}0)${RST} Volver"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " opt
        RESULTADO=""

        case $opt in
            [Aa])
                for idx in "${!apps[@]}"; do
                    echo -e "  ${Y}[*]${RST} Instalando: ${names[$idx]}..."
                    chmod +x "${apps[$idx]}"
                    sudo bash "${apps[$idx]}" 2>&1 | tail -3
                    echo -e "  ${G}[+]${RST} ${names[$idx]} completado\n"
                done
                RESULTADO="  ${G}[+]${RST} Todas las apps instaladas"
                read -rp "  Enter para continuar..."
                ;;
            0) return ;;
            *)
                if [[ "$opt" =~ ^[0-9]+$ ]] && (( opt >= 1 && opt < i )); then
                    local idx=$((opt-1))
                    echo -e "\n  ${Y}[*]${RST} Instalando: ${names[$idx]}..."
                    chmod +x "${apps[$idx]}"
                    sudo bash "${apps[$idx]}" 2>&1
                    RESULTADO="  ${G}[+]${RST} ${names[$idx]} completado"
                    read -rp "  Enter para continuar..."
                else
                    RESULTADO="  ${R}Opcion invalida${RST}"
                fi
                ;;
        esac
    done
}

# =============================================================================
# 3. CONFIGURACION DE RED
# =============================================================================
menu_red() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Configuracion de Red ──${RST}\n"

        # Detectar interfaces
        local ifaces=() ips=() states=()
        for iface in $(ls /sys/class/net/ | grep -v lo | sort); do
            ifaces+=("$iface")
            local ip=$(ip -4 addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
            local state=$(cat /sys/class/net/"$iface"/operstate 2>/dev/null)
            [[ -z "$ip" ]] && ip="Disconnected"
            ips+=("$ip")
            states+=("$state")
        done

        echo -e "  ${B}Interfaces:${RST}\n"
        for i in "${!ifaces[@]}"; do
            local icon="${G}●${RST}"
            [[ "${ips[$i]}" == "Disconnected" ]] && icon="${R}○${RST}"
            echo -e "  $icon ${B}${ifaces[$i]}${RST} — ${ips[$i]} ${DIM}(${states[$i]})${RST}"
        done

        # Primaria/Secundaria
        local primary="" secondary=""
        for i in "${!ifaces[@]}"; do
            if [[ "${ips[$i]}" != "Disconnected" && -z "$primary" ]]; then
                primary="${ifaces[$i]} (${ips[$i]})"
            elif [[ -z "$secondary" ]]; then
                secondary="${ifaces[$i]}"
            fi
        done
        echo ""
        echo -e "  Primaria:   ${G}${primary:-Ninguna}${RST}"
        [[ -n "$secondary" ]] && echo -e "  Secundaria: ${Y}${secondary} — No configurada${RST}" || echo -e "  Secundaria: ${R}No detectada${RST}"

        echo ""
        echo -e "  ${G}1)${RST} Configurar interfaz (DHCP)"
        echo -e "  ${G}2)${RST} Reiniciar NetworkManager"
        echo -e "  ${G}3)${RST} DHCP en todas"
        echo -e "  ${G}0)${RST} Volver"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " opt
        RESULTADO=""

        case $opt in
            1)
                echo -e "\n  Interfaces:"
                for i in "${!ifaces[@]}"; do echo -e "    $((i+1))) ${ifaces[$i]} — ${ips[$i]}"; done
                read -rp "  Seleccionar: " sel
                if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#ifaces[@]} )); then
                    local selected="${ifaces[$((sel-1))]}"
                    echo -e "  ${Y}[*]${RST} Solicitando IP para $selected..."
                    sudo ip link set "$selected" up 2>/dev/null
                    sudo dhclient -r "$selected" 2>/dev/null
                    sudo dhclient "$selected" 2>/dev/null || sudo dhcpcd "$selected" 2>/dev/null
                    sleep 2
                    local new_ip=$(ip -4 addr show "$selected" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
                    [[ -n "$new_ip" ]] && RESULTADO="  ${G}[+]${RST} $selected: $new_ip" || RESULTADO="  ${R}[!]${RST} $selected: Disconnected"
                fi
                ;;
            2)
                sudo systemctl restart NetworkManager 2>/dev/null && sleep 2 && RESULTADO="  ${G}[+]${RST} NetworkManager reiniciado" || RESULTADO="  ${R}[!]${RST} Error reiniciando NM"
                ;;
            3)
                for iface in "${ifaces[@]}"; do
                    sudo dhclient "$iface" 2>/dev/null &
                done
                sleep 3
                RESULTADO="  ${G}[+]${RST} DHCP solicitado en todas las interfaces"
                ;;
            0) return ;;
            *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
        esac
    done
}

# =============================================================================
# 4. VALIDAR SCRIPTS Y FUNCIONES
# =============================================================================
menu_validar() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Validar Scripts y Funciones ──${RST}\n"
        echo -e "  ${G}1)${RST} Validar TODOS"
        echo -e "  ${G}2)${RST} Validar uno por uno (interactivo)"
        echo -e "  ${G}3)${RST} Verificar comandos en PATH"
        echo -e "  ${G}4)${RST} Enlazar scripts al PATH (resolver 'command not found')"
        echo -e "  ${G}0)${RST} Volver"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " opt
        RESULTADO=""

        case $opt in
            1) validar_todos ;;
            2) validar_interactivo ;;
            3) verificar_path ;;
            4) enlazar_scripts ;;
            0) return ;;
            *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
        esac
    done
}

validar_todos() {
    RESULTADO=""
    local total=0 ok=0 fail=0

    # Scripts de servicios
    if [[ -d "$SCRIPTS_DIR" ]]; then
        while IFS= read -r script; do
            ((total++))
            local name=$(basename "$script")
            if [[ ! -x "$script" ]]; then
                chmod +x "$script"
                RESULTADO+="  ${Y}⚠${RST} $name → +x corregido\n"
            fi
            if bash -n "$script" 2>/dev/null; then
                RESULTADO+="  ${G}✓${RST} $name\n"
                ((ok++))
            elif python3 -c "import py_compile; py_compile.compile('$script', doraise=True)" 2>/dev/null; then
                RESULTADO+="  ${G}✓${RST} $name (python)\n"
                ((ok++))
            else
                RESULTADO+="  ${R}✗${RST} $name (error sintaxis)\n"
                ((fail++))
            fi
        done < <(find "$SCRIPTS_DIR" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort)
    fi

    # Scripts bspwm
    if [[ -d "$USER_HOME/.config/bspwm/scripts" ]]; then
        while IFS= read -r script; do
            ((total++))
            local name=$(basename "$script")
            [[ ! -x "$script" ]] && chmod +x "$script"
            if bash -n "$script" 2>/dev/null || python3 -c "import py_compile; py_compile.compile('$script', doraise=True)" 2>/dev/null; then
                RESULTADO+="  ${G}✓${RST} $name (bspwm)\n"
                ((ok++))
            else
                RESULTADO+="  ${R}✗${RST} $name (bspwm - error)\n"
                ((fail++))
            fi
        done < <(find "$USER_HOME/.config/bspwm/scripts" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort)
    fi

    RESULTADO+="\n  ${B}Total: $total | ${G}OK: $ok${RST} | ${R}Fallos: $fail${RST}"
}

validar_interactivo() {
    local scripts=()
    while IFS= read -r s; do scripts+=("$s"); done < <(find "$SCRIPTS_DIR" "$USER_HOME/.config/bspwm/scripts" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | sort)

    [[ ${#scripts[@]} -eq 0 ]] && { RESULTADO="  ${R}No se encontraron scripts${RST}"; return; }

    for script in "${scripts[@]}"; do
        limpiar; dibujar_cabecera
        local name=$(basename "$script")
        echo -e "\n  ${B}Script:${RST} $name"
        echo -e "  ${DIM}Ruta: $script${RST}\n"

        [[ ! -x "$script" ]] && { chmod +x "$script"; echo -e "  ${Y}[~]${RST} Permiso +x corregido"; }

        if bash -n "$script" 2>/dev/null; then
            echo -e "  ${G}[+]${RST} Sintaxis OK"
        elif python3 -c "import py_compile; py_compile.compile('$script', doraise=True)" 2>/dev/null; then
            echo -e "  ${G}[+]${RST} Sintaxis Python OK"
        else
            echo -e "  ${R}[!]${RST} Error de sintaxis"
        fi

        echo ""
        echo -e "  ${G}Enter${RST}=siguiente | ${Y}e${RST}=ejecutar | ${R}q${RST}=salir"
        read -rp "  > " action
        case $action in
            e) echo ""; bash "$script" 2>&1 | head -20; echo ""; read -rp "  Enter..." ;;
            q) return ;;
        esac
    done
    RESULTADO="  ${G}[+]${RST} Validacion interactiva completada"
}

verificar_path() {
    RESULTADO="  ${B}Comandos en PATH:${RST}\n\n"
    local cmds=(bspwm sxhkd polybar picom rofi kitty nvim zsh fzf bat bspc)
    for cmd in "${cmds[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            RESULTADO+="  ${G}✓${RST} $cmd → $(command -v "$cmd")\n"
        else
            RESULTADO+="  ${R}✗${RST} $cmd → NO ENCONTRADO\n"
        fi
    done

    # Verificar funciones/scripts de servicios
    RESULTADO+="\n  ${B}Scripts de servicios:${RST}\n\n"
    if [[ -d "$SCRIPTS_DIR/servicios" ]]; then
        for script in "$SCRIPTS_DIR/servicios/"*.sh; do
            [[ -f "$script" ]] || continue
            local name=$(basename "$script" .sh)
            if command -v "$name" &>/dev/null || [[ -L "$USER_HOME/.local/bin/$name" ]]; then
                RESULTADO+="  ${G}✓${RST} $name\n"
            else
                RESULTADO+="  ${R}✗${RST} $name (no en PATH → usar opcion 4)\n"
            fi
        done
    fi
}

enlazar_scripts() {
    mkdir -p "$USER_HOME/.local/bin"
    local count=0

    # Enlazar scripts de servicios
    if [[ -d "$SCRIPTS_DIR/servicios" ]]; then
        for script in "$SCRIPTS_DIR/servicios/"*.sh; do
            [[ -f "$script" ]] || continue
            chmod +x "$script"
            local name=$(basename "$script" .sh)
            ln -sf "$script" "$USER_HOME/.local/bin/$name"
            ((count++))
        done
    fi

    # Enlazar scripts de bash
    if [[ -d "$SCRIPTS_DIR/bash" ]]; then
        for script in "$SCRIPTS_DIR/bash/"*.sh; do
            [[ -f "$script" ]] || continue
            chmod +x "$script"
            local name=$(basename "$script" .sh)
            ln -sf "$script" "$USER_HOME/.local/bin/$name"
            ((count++))
        done
    fi

    # Asegurar PATH
    if ! grep -q "\.local/bin" "$USER_HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.zshrc"
    fi

    RESULTADO="  ${G}[+]${RST} $count scripts enlazados en ~/.local/bin/\n  ${DIM}Reinicia terminal o ejecuta: source ~/.zshrc${RST}\n\n  ${B}Ahora puedes usar:${RST}\n"
    if [[ -d "$SCRIPTS_DIR/servicios" ]]; then
        for script in "$SCRIPTS_DIR/servicios/"*.sh; do
            [[ -f "$script" ]] || continue
            RESULTADO+="    ${G}●${RST} $(basename "$script" .sh)\n"
        done
    fi
}

# =============================================================================
# BUCLE PRINCIPAL
# =============================================================================
RESULTADO=""
while true; do
    redibujar
    read -rp "  Opcion: " opt
    RESULTADO=""
    case $opt in
        1) menu_p10k ;;
        2) menu_apps ;;
        3) menu_red ;;
        4) menu_validar ;;
        0) limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
    esac
done
