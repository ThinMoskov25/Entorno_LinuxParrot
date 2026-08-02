#!/bin/bash
# =============================================================================
# startssh - Gestor interactivo de conexiones SSH
# Autor: Moskov | Interfaz: TUI estatica ANSI
# =============================================================================

# ─── FIX TERMINAL ────────────────────────────────────────────────────────────
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == "xterm-kitty" ]] && export TERM="xterm-256color"

# ─── COLORES ─────────────────────────────────────────────────────────────────
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# ─── VARIABLES ───────────────────────────────────────────────────────────────
CONEXIONES_ROOT="${HOME}/Desktop/$(whoami)/Ciberseguridad/4_Servicios/Conexiones_Servicios"
WORK_DIR="$CONEXIONES_ROOT/SSH"
PROFILES_FILE="$WORK_DIR/ssh_profiles.conf"
mkdir -p "$WORK_DIR" && touch "$PROFILES_FILE"
RESULTADO=""

# ─── TUI ENGINE ──────────────────────────────────────────────────────────────
get_ip() { hostname -I | awk '{print $1}'; }
limpiar() { printf '\033[H\033[J'; }

dibujar_cabecera() {
    local estado="${R}INACTIVO${RST}"
    systemctl is-active --quiet ssh 2>/dev/null && estado="${G}ACTIVO${RST}"
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "${C}              CONEXIONES SSH - StartSSH${RST}"
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "  ${DIM}IP: $(get_ip) | SSH: ${RST}$estado"
    echo -e "${C}  ────────────────────────────────────────────────────────${RST}"
}

dibujar_menu() {
    echo ""
    echo -e "  ${G}1)${RST} Activar SSH"
    echo -e "  ${G}2)${RST} Detener SSH"
    echo -e "  ${G}3)${RST} Conectar a host remoto"
    echo -e "  ${G}4)${RST} Perfiles guardados"
    echo -e "  ${G}5)${RST} Agregar perfil"
    echo -e "  ${G}6)${RST} Eliminar perfil"
    echo -e "  ${G}7)${RST} Generar llaves SSH"
    echo -e "  ${G}8)${RST} Copiar llave a host"
    echo -e "  ${G}9)${RST} Estado del servicio"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
}

dibujar_resultado() {
    if [[ -n "$RESULTADO" ]]; then
        echo -e "${C}  ─── Resultado ─────────────────────────────────────────${RST}"
        echo -e "$RESULTADO"
        echo -e "${C}  ───────────────────────────────────────────────────────${RST}"
    fi
}

redibujar() { limpiar; dibujar_cabecera; dibujar_menu; dibujar_resultado; }

# ─── FUNCIONES ───────────────────────────────────────────────────────────────

ssh_activar() {
    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
    sleep 1
    if systemctl is-active --quiet ssh 2>/dev/null; then
        local port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
        RESULTADO="  ${G}[+] SSH ACTIVO${RST}\n  Host: ${C}$(get_ip)${RST} | Puerto: ${C}${port:-22}${RST}\n  Comando: ${C}ssh $(whoami)@$(get_ip)${RST}"
    else
        RESULTADO="  ${R}[!] No se pudo activar${RST}"
    fi
}

ssh_detener() {
    sudo systemctl stop ssh 2>/dev/null || sudo systemctl stop sshd 2>/dev/null
    RESULTADO="  ${G}[+] SSH detenido${RST}"
}

ssh_conectar() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Conectar a Host ──${RST}\n"
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " port; port=${port:-22}
    read -rp "  Usuario [root]: " user; user=${user:-root}
    echo -e "\n${Y}  [*] Conectando...${RST}\n"
    ssh -o ConnectTimeout=10 -p "$port" "$user@$host"
    echo ""; read -rp "  ENTER para volver..." _
    RESULTADO=""
}

ssh_perfiles() {
    if [[ ! -s "$PROFILES_FILE" ]]; then
        RESULTADO="  ${Y}No hay perfiles. Usa opcion 5.${RST}"; return
    fi
    RESULTADO="  ${B}Perfiles:${RST}\n"
    local i=1
    while IFS='|' read -r nombre host puerto usuario; do
        RESULTADO+="  ${G}$i)${RST} ${B}$nombre${RST} -> $usuario@$host:$puerto\n"
        ((i++))
    done < "$PROFILES_FILE"

    redibujar
    read -rp "  Conectar a (0=volver): " sel
    [[ "$sel" == "0" || -z "$sel" ]] && { RESULTADO=""; return; }
    local linea=$(sed -n "${sel}p" "$PROFILES_FILE")
    if [[ -n "$linea" ]]; then
        IFS='|' read -r nombre host puerto usuario <<< "$linea"
        echo -e "\n${Y}  [*] Conectando a $nombre...${RST}\n"
        ssh -o ConnectTimeout=10 -p "$puerto" "$usuario@$host"
        echo ""; read -rp "  ENTER para volver..." _
    fi
    RESULTADO=""
}

ssh_agregar() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Agregar Perfil ──${RST}\n"
    read -rp "  Nombre: " nombre
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " puerto; puerto=${puerto:-22}
    read -rp "  Usuario [root]: " usuario; usuario=${usuario:-root}
    echo "$nombre|$host|$puerto|$usuario" >> "$PROFILES_FILE"
    RESULTADO="  ${G}[+]${RST} Perfil '$nombre' guardado"
}

ssh_eliminar() {
    if [[ ! -s "$PROFILES_FILE" ]]; then
        RESULTADO="  ${Y}No hay perfiles${RST}"; return
    fi
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Eliminar Perfil ──${RST}\n"
    local i=1
    while IFS='|' read -r nombre host puerto usuario; do
        echo -e "  ${R}$i)${RST} $nombre -> $usuario@$host:$puerto"
        ((i++))
    done < "$PROFILES_FILE"
    echo ""; read -rp "  Numero (0=cancelar): " sel
    [[ "$sel" == "0" || -z "$sel" ]] && { RESULTADO=""; return; }
    sed -i "${sel}d" "$PROFILES_FILE"
    RESULTADO="  ${G}[+] Eliminado${RST}"
}

ssh_genkeys() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Generar Llaves ──${RST}\n"
    local key="$HOME/.ssh/id_ed25519"
    if [[ -f "$key" ]]; then
        echo -e "  ${Y}Ya existe: $key${RST}"
        read -rp "  Sobreescribir? (s/n): " r
        [[ "$r" != "s" ]] && { RESULTADO=""; return; }
    fi
    ssh-keygen -t ed25519 -f "$key" -C "$(whoami)@$(hostname)"
    RESULTADO="  ${G}[+] Llave generada${RST}\n  $(cat "${key}.pub")"
}

ssh_copykey() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Copiar Llave ──${RST}\n"
    local key="$HOME/.ssh/id_ed25519.pub"
    [[ ! -f "$key" ]] && key="$HOME/.ssh/id_rsa.pub"
    if [[ ! -f "$key" ]]; then
        RESULTADO="  ${R}No hay llave. Genera una (opcion 7)${RST}"; return
    fi
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " port; port=${port:-22}
    read -rp "  Usuario [root]: " user; user=${user:-root}
    ssh-copy-id -i "$key" -p "$port" "$user@$host"
    RESULTADO="  ${G}[+] Llave copiada${RST}"
}

ssh_estado() {
    RESULTADO=""
    if systemctl is-active --quiet ssh 2>/dev/null; then
        RESULTADO+="  Servicio: ${G}ACTIVO${RST}\n"
    else
        RESULTADO+="  Servicio: ${R}INACTIVO${RST}\n"
    fi
    RESULTADO+="  IP:       ${C}$(get_ip)${RST}\n"
    local port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    RESULTADO+="  Puerto:   ${port:-22}\n"
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        RESULTADO+="  Llave:    ${G}ed25519${RST}\n"
    elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
        RESULTADO+="  Llave:    ${G}RSA${RST}\n"
    else
        RESULTADO+="  Llave:    ${Y}No generada${RST}\n"
    fi
    local n=$(wc -l < "$PROFILES_FILE" 2>/dev/null || echo 0)
    RESULTADO+="  Perfiles: $n guardados"
}

# ─── BUCLE PRINCIPAL ─────────────────────────────────────────────────────────
while true; do
    redibujar
    read -rp "  Opcion: " opt
    RESULTADO=""
    case $opt in
        1) ssh_activar ;; 2) ssh_detener ;; 3) ssh_conectar ;;
        4) ssh_perfiles ;; 5) ssh_agregar ;; 6) ssh_eliminar ;;
        7) ssh_genkeys ;; 8) ssh_copykey ;; 9) ssh_estado ;;
        0) limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Invalido${RST}" ;;
    esac
done
