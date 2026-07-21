#!/bin/bash
# =============================================================================
# startssh - Gestor interactivo de conexiones SSH
# Autor: Moskov
# Uso: startssh
# =============================================================================

G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

CONEXIONES_ROOT="/home/moskov/Desktop/Moskov/Ciberseguridad/04_Servicios/Conexiones Servicios"
WORK_DIR="$CONEXIONES_ROOT/SSH"
PROFILES_FILE="$WORK_DIR/ssh_profiles.conf"
mkdir -p "$WORK_DIR" && touch "$PROFILES_FILE"

get_ip() { hostname -I | awk '{print $1}'; }

banner() {
    clear
    echo -e "${C}"
    echo "  ========================================"
    echo "       CONEXIONES SSH - StartSSH"
    echo "  ========================================"
    echo "   Gestiona servicio SSH y conexiones"
    echo "  ========================================"
    echo -e "${RST}"
}

menu_principal() {
    banner
    echo -e "  ${DIM}IP Local: $(get_ip)${RST}"
    if systemctl is-active --quiet ssh 2>/dev/null; then
        echo -e "  ${G}[+] SSH ACTIVO${RST}\n"
    else
        echo -e "  ${R}[-] SSH INACTIVO${RST}\n"
    fi
    echo -e "  ${G}1)${RST} Activar servicio SSH"
    echo -e "  ${G}2)${RST} Detener servicio SSH"
    echo -e "  ${G}3)${RST} Conectar a host remoto"
    echo -e "  ${G}4)${RST} Perfiles guardados"
    echo -e "  ${G}5)${RST} Agregar perfil"
    echo -e "  ${G}6)${RST} Eliminar perfil"
    echo -e "  ${G}7)${RST} Generar llaves SSH"
    echo -e "  ${G}8)${RST} Copiar llave a host remoto"
    echo -e "  ${G}9)${RST} Estado del servicio"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
    read -rp "  Opcion: " opt
    case $opt in
        1) ssh_activar ;; 2) ssh_detener ;; 3) ssh_conectar ;;
        4) ssh_perfiles ;; 5) ssh_agregar ;; 6) ssh_eliminar ;;
        7) ssh_genkeys ;; 8) ssh_copykey ;; 9) ssh_estado ;;
        0) echo -e "\n${G}  Hasta luego!${RST}\n"; exit 0 ;;
        *) echo -e "${R}  [!] Opcion no valida${RST}"; sleep 1; menu_principal ;;
    esac
}

ssh_activar() {
    banner
    echo -e "${Y}  [*] Activando SSH...${RST}"
    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null
    sleep 1
    if systemctl is-active --quiet ssh 2>/dev/null; then
        local ip=$(get_ip)
        local port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
        port=${port:-22}
        echo -e "\n${G}  SSH ACTIVO${RST}"
        echo -e "  Host:    ${C}$ip${RST}"
        echo -e "  Puerto:  ${C}$port${RST}"
        echo -e "  Comando: ${C}ssh $(whoami)@$ip${RST}"
    else
        echo -e "${R}  [!] No se pudo activar.${RST}"
    fi
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_detener() {
    banner
    sudo systemctl stop ssh 2>/dev/null || sudo systemctl stop sshd 2>/dev/null
    echo -e "${G}  [+] SSH detenido.${RST}"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_conectar() {
    banner
    echo -e "${C}  Conectar a host remoto${RST}\n"
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " port; port=${port:-22}
    read -rp "  Usuario [root]: " user; user=${user:-root}
    echo -e "\n${Y}  [*] Conectando a $user@$host:$port...${RST}\n"
    ssh -o ConnectTimeout=10 -p "$port" "$user@$host"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_perfiles() {
    banner
    echo -e "${C}  Perfiles SSH guardados${RST}\n"
    if [[ ! -s "$PROFILES_FILE" ]]; then
        echo -e "${Y}  No hay perfiles. Usa opcion 5.${RST}"
        echo ""; read -rp "  ENTER para volver..." _; menu_principal; return
    fi
    local i=1
    while IFS='|' read -r nombre host puerto usuario; do
        echo -e "  ${G}$i)${RST} ${B}$nombre${RST} -> $usuario@$host:$puerto"
        ((i++))
    done < "$PROFILES_FILE"
    echo ""
    read -rp "  Selecciona (0=volver): " sel
    [[ "$sel" == "0" ]] && { menu_principal; return; }
    local linea=$(sed -n "${sel}p" "$PROFILES_FILE")
    if [[ -n "$linea" ]]; then
        IFS='|' read -r nombre host puerto usuario <<< "$linea"
        echo -e "\n${Y}  [*] Conectando a $nombre...${RST}\n"
        ssh -o ConnectTimeout=10 -p "$puerto" "$usuario@$host"
    else
        echo -e "${R}  [!] Seleccion invalida.${RST}"
    fi
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_agregar() {
    banner
    echo -e "${C}  Agregar perfil SSH${RST}\n"
    read -rp "  Nombre (ej: htb, lab1): " nombre
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " puerto; puerto=${puerto:-22}
    read -rp "  Usuario [root]: " usuario; usuario=${usuario:-root}
    echo "$nombre|$host|$puerto|$usuario" >> "$PROFILES_FILE"
    echo -e "\n${G}  [+] Perfil '$nombre' guardado.${RST}"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_eliminar() {
    banner
    echo -e "${C}  Eliminar perfil${RST}\n"
    if [[ ! -s "$PROFILES_FILE" ]]; then
        echo -e "${Y}  No hay perfiles.${RST}"
        echo ""; read -rp "  ENTER para volver..." _; menu_principal; return
    fi
    local i=1
    while IFS='|' read -r nombre host puerto usuario; do
        echo -e "  ${R}$i)${RST} $nombre -> $usuario@$host:$puerto"
        ((i++))
    done < "$PROFILES_FILE"
    echo ""
    read -rp "  Numero a eliminar (0=cancelar): " sel
    [[ "$sel" == "0" ]] && { menu_principal; return; }
    sed -i "${sel}d" "$PROFILES_FILE"
    echo -e "${G}  [+] Eliminado.${RST}"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_genkeys() {
    banner
    echo -e "${C}  Generar llaves SSH${RST}\n"
    local key="$HOME/.ssh/id_ed25519"
    if [[ -f "$key" ]]; then
        echo -e "${Y}  [!] Ya existe: $key${RST}"
        read -rp "  Sobreescribir? (s/n): " r
        [[ "$r" != "s" ]] && { menu_principal; return; }
    fi
    ssh-keygen -t ed25519 -f "$key" -C "$(whoami)@$(hostname)"
    echo -e "\n${G}  [+] Llave generada.${RST}"
    echo "  Publica:"; cat "${key}.pub"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_copykey() {
    banner
    echo -e "${C}  Copiar llave publica a host${RST}\n"
    local key="$HOME/.ssh/id_ed25519.pub"
    [[ ! -f "$key" ]] && key="$HOME/.ssh/id_rsa.pub"
    if [[ ! -f "$key" ]]; then
        echo -e "${R}  [!] No hay llave. Genera una (opcion 7).${RST}"
        echo ""; read -rp "  ENTER para volver..." _; menu_principal; return
    fi
    read -rp "  Host: " host
    read -rp "  Puerto [22]: " port; port=${port:-22}
    read -rp "  Usuario [root]: " user; user=${user:-root}
    echo -e "\n${Y}  [*] Copiando llave...${RST}\n"
    ssh-copy-id -i "$key" -p "$port" "$user@$host"
    echo -e "\n${G}  [+] Listo. Conectate sin password.${RST}"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

ssh_estado() {
    banner
    echo -e "${C}  Estado SSH${RST}\n  ─────────────────────────"
    if systemctl is-active --quiet ssh 2>/dev/null; then
        echo -e "  Servicio: ${G}ACTIVO${RST}"
    else
        echo -e "  Servicio: ${R}INACTIVO${RST}"
    fi
    echo -e "  IP:       $(get_ip)"
    local port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    echo -e "  Puerto:   ${port:-22}"
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        echo -e "  Llave:    ${G}ed25519${RST}"
    elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
        echo -e "  Llave:    ${G}RSA${RST}"
    else
        echo -e "  Llave:    ${Y}No generada${RST}"
    fi
    local n=$(wc -l < "$PROFILES_FILE" 2>/dev/null || echo 0)
    echo -e "  Perfiles: $n guardados"
    echo -e "  ─────────────────────────"
    echo ""; read -rp "  ENTER para volver..." _; menu_principal
}

menu_principal
