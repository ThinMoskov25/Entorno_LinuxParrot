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
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    CURRENT_USER="$SUDO_USER"
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    CURRENT_USER="$(whoami)"
    USER_HOME="$HOME"
fi
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
    echo -e "  ${G}5)${RST} Ver funciones y comandos disponibles"
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
    local src="$USER_HOME/.p10k.zsh"
    [[ ! -f "$src" ]] && src="/tmp/entorno/zsh/.p10k.zsh"
    if [[ ! -f "$src" ]]; then
        RESULTADO="  ${R}[!]${RST} Primero configura P10k (opcion 1 o 2)"
        return
    fi

    sudo cp -f "$src" /root/.p10k.zsh
    [[ -d "$USER_HOME/powerlevel10k" && ! -d /root/powerlevel10k ]] && \
        sudo cp -r "$USER_HOME/powerlevel10k" /root/powerlevel10k

    sudo tee /root/.zshrc > /dev/null << 'ROOTZSH'
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

    sudo chsh -s /usr/bin/zsh root 2>/dev/null
    RESULTADO="  ${G}[+]${RST} P10k replicado en root\n  ${G}[+]${RST} Shell root: zsh\n  ${G}[+]${RST} Autocompletado case-insensitive\n  ${DIM}sudo su para verificar${RST}"
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
    RESULTADO="  ${B}Los scripts de servicios se acceden via aliases:${RST}\n\n"
    RESULTADO+="  ${G}startftp${RST}       → Gestor FTP\n"
    RESULTADO+="  ${G}startssh${RST}       → Gestor SSH\n"
    RESULTADO+="  ${G}startfire${RST}      → Gestor Firewall (sudo)\n"
    RESULTADO+="  ${G}compartidos${RST}    → Gestor Samba (sudo)\n"
    RESULTADO+="\n  ${DIM}Estos aliases estan definidos en ~/.zshrc${RST}\n"
    RESULTADO+="  ${DIM}Si no funcionan, ejecuta: source ~/.zshrc${RST}\n"

    # Verificar que los scripts existen y tienen permisos
    local ciber="$USER_HOME/Desktop/$CURRENT_USER/Ciberseguridad"
    if [[ -d "$ciber/1_Scripts/servicios" ]]; then
        RESULTADO+="\n  ${B}Estado de scripts:${RST}\n"
        for script in "$ciber/1_Scripts/servicios/"*.sh; do
            [[ -f "$script" ]] || continue
            local name=$(basename "$script")
            if [[ -x "$script" ]]; then
                RESULTADO+="  ${G}✓${RST} $name\n"
            else
                chmod +x "$script"
                RESULTADO+="  ${Y}⚠${RST} $name → permiso corregido\n"
            fi
        done
    fi
}

# =============================================================================
# 5. SNAPSHOT DEL SISTEMA (Timeshift)
# =============================================================================
menu_snapshot() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Snapshot del Sistema (Timeshift) ──${RST}\n"

        # Verificar si timeshift está instalado
        if ! command -v timeshift &>/dev/null; then
            echo -e "  ${R}[!]${RST} Timeshift no instalado"
            echo -e "  ${Y}    Instalando...${RST}"
            sudo apt-get install -y timeshift 2>/dev/null
            if ! command -v timeshift &>/dev/null; then
                RESULTADO="  ${R}[!]${RST} No se pudo instalar timeshift"
                read -rp "  Enter..."; return
            fi
        fi

        # Listar snapshots existentes
        echo -e "  ${B}Snapshots existentes:${RST}\n"
        local snaps=$(sudo timeshift --list 2>/dev/null | grep -E "^[0-9]" || true)
        if [[ -n "$snaps" ]]; then
            echo "$snaps" | while IFS= read -r line; do
                echo -e "    ${G}●${RST} $line"
            done
        else
            echo -e "    ${DIM}Ninguna${RST}"
        fi

        echo ""
        echo -e "  ${G}1)${RST} Crear snapshot ahora"
        echo -e "  ${G}2)${RST} Listar snapshots"
        echo -e "  ${G}3)${RST} Restaurar snapshot"
        echo -e "  ${G}4)${RST} Eliminar snapshot"
        echo -e "  ${G}0)${RST} Volver"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " opt
        RESULTADO=""

        case $opt in
            1)
                read -rp "  Comentario (opcional): " comment
                comment="${comment:-Snapshot manual}"
                echo -e "\n  ${Y}[*]${RST} Creando snapshot..."
                sudo timeshift --create --comments "$comment" 2>&1 | tail -5
                RESULTADO="  ${G}[+]${RST} Snapshot creado: $comment"
                read -rp "  Enter..."
                ;;
            2)
                limpiar; dibujar_cabecera
                echo -e "\n  ${B}Snapshots:${RST}\n"
                sudo timeshift --list 2>&1
                read -rp "  Enter..."
                ;;
            3)
                echo -e "\n  ${R}[!] ATENCION: Restaurar reiniciara el sistema${RST}"
                read -rp "  Confirmar (si/no): " conf
                if [[ "$conf" == "si" ]]; then
                    sudo timeshift --restore
                fi
                ;;
            4)
                echo -e "\n  Ingresa el numero del snapshot a eliminar:"
                sudo timeshift --list 2>/dev/null | grep -E "^[0-9]"
                read -rp "  Numero: " num
                [[ -n "$num" ]] && sudo timeshift --delete --snapshot "$num" 2>&1
                RESULTADO="  ${G}[+]${RST} Snapshot eliminado"
                read -rp "  Enter..."
                ;;
            0) return ;;
            *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
        esac
    done
}

# =============================================================================
# 5. VER FUNCIONES Y COMANDOS DISPONIBLES
# =============================================================================
menu_ver_funciones() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Funciones y Comandos Disponibles ──${RST}\n"
    echo -e "  ${C}═══ FUNCIONES ZSH (definidas en ~/.zshrc) ═══${RST}\n"
    echo -e "  ${G}refresh${RST}              Recargar .zshrc sin cerrar terminal"
    echo -e "  ${G}settarget${RST} IP NOMBRE  Establecer target para polybar"
    echo -e "  ${G}cleartarget${RST}          Limpiar target"
    echo -e "  ${G}wificonect${RST}           Menu WiFi interactivo (Python)"
    echo -e "  ${G}wifiscan${RST}             Modo monitor TL-WN722N"
    echo -e "  ${G}resnet${RST}               Restaurar servicios de red"
    echo -e "  ${G}mkt${RST}                  Crear dirs pentesting (nmap/content/scripts/vpn)"
    echo -e "  ${G}whichsystem${RST} IP       Detectar SO por TTL"
    echo -e "  ${G}extractPorts${RST} FILE    Extraer puertos de nmap grepable"
    echo -e "  ${G}infbat${RST}               Fecha/hora + bateria"
    echo -e "  ${G}netaudit${RST}             Auditoria de red (modo menu)"
    echo -e "  ${G}netscan${RST} CMD          Auditoria de red (modo directo)"
    echo ""
    echo -e "  ${C}═══ ALIASES DE SERVICIOS ═══${RST}\n"
    echo -e "  ${G}startftp${RST}             Gestor FTP (pyftpdlib)"
    echo -e "  ${G}startssh${RST}             Gestor SSH (conexiones/perfiles/llaves)"
    echo -e "  ${G}startfire${RST}            Gestor Firewall UFW (requiere sudo)"
    echo -e "  ${G}compartidos${RST}          Gestor Samba (requiere sudo)"
    echo -e "  ${G}cdm${RST}                  Ir a ~/Desktop/usuario/Ciberseguridad"
    echo -e "  ${G}update${RST}               Actualizar sistema + snapshot timeshift"
    echo ""
    echo -e "  ${C}═══ ALIASES UTILES ═══${RST}\n"
    echo -e "  ${G}cat${RST}                  bat (sintaxis resaltada)"
    echo -e "  ${G}ls/ll/la/lla${RST}         lsd (mejorado)"
    echo ""
    echo -e "  ${C}═══ ATAJOS DE TECLADO (sxhkd) ═══${RST}\n"
    echo -e "  ${G}Super+Return${RST}         Kitty"
    echo -e "  ${G}Super+d${RST}              Rofi"
    echo -e "  ${G}Super+Shift+f${RST}        Firefox"
    echo -e "  ${G}Super+Shift+g${RST}        Chrome"
    echo -e "  ${G}Super+Shift+p${RST}        Screenshot (flameshot)"
    echo -e "  ${G}Super+Shift+x${RST}        Lock (i3lock-fancy)"
    echo -e "  ${G}Super+q${RST}              Cerrar ventana"
    echo -e "  ${G}Super+{1-0}${RST}          Escritorios 1-10"
    echo -e "  ${G}Super+Alt+q${RST}          Salir bspwm"
    echo -e "  ${G}Super+Alt+r${RST}          Reiniciar bspwm"
    echo ""
    echo -e "  ${C}═══ SCRIPTS POLYBAR ═══${RST}\n"
    echo -e "  ${G}ethernet.sh${RST}          IP ethernet en polybar"
    echo -e "  ${G}wifi.sh${RST}              IP wifi en polybar"
    echo -e "  ${G}vpn.sh${RST}               IP VPN (tun0) en polybar"
    echo -e "  ${G}target.sh${RST}            Target actual en polybar"
    echo ""
    read -rp "  Enter para volver..."
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
        5) menu_ver_funciones ;;
        0) limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
    esac
done
