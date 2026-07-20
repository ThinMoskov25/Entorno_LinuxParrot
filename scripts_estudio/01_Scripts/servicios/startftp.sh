#!/bin/bash
# =============================================================================
# startftp - Gestor interactivo de servidor FTP
# Autor: Moskov
# Descripcion: Aplicativo para levantar un servidor FTP seguro con opciones
#              de configuracion, usuarios temporales y logs.
# Uso: startftp (o sudo startftp para opciones avanzadas)
# =============================================================================

# Colores
G="\033[0;32m"    # Verde
C="\033[0;36m"    # Cyan
Y="\033[1;33m"    # Amarillo
R="\033[0;31m"    # Rojo
B="\033[1;37m"    # Blanco bold
DIM="\033[2m"     # Dim
RST="\033[0m"     # Reset

# Directorio de trabajo
WORK_DIR="/home/moskov/Desktop/Moskov/Ciberseguridad/04_Servicios/FTP"
LOG_DIR="$WORK_DIR/logs"
FTP_SHARE="/home/moskov/Desktop/FTP_Share"
mkdir -p "$LOG_DIR" "$FTP_SHARE"

# Auto-instalar pyftpdlib si no existe
if ! python3 -m pyftpdlib --help &>/dev/null; then
    echo -e "${Y}  [*] Instalando pyftpdlib...${RST}"
    pip install pyftpdlib --break-system-packages 2>/dev/null || pip install pyftpdlib 2>/dev/null
fi

# Variables globales
FTP_PID=""
FTP_USER=""
FTP_PASS=""
FTP_PORT="2121"

banner() {
    clear
    echo -e "${C}"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║         SERVIDOR FTP - StartFTP           ║"
    echo "  ╠═══════════════════════════════════════════╣"
    echo "  ║  Gestiona tu servidor FTP de forma segura ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo -e "${RST}"
}

get_ip() {
    hostname -I | awk '{print $1}'
}

# Menu principal
menu_principal() {
    banner
    local ip=$(get_ip)
    echo -e "  ${DIM}IP Local: $ip${RST}\n"

    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        echo -e "  ${G}● Servidor FTP ACTIVO (PID: $FTP_PID)${RST}"
        echo -e "  ${DIM}  Puerto: $FTP_PORT | Usuario: $FTP_USER${RST}\n"
    else
        echo -e "  ${R}○ Servidor FTP INACTIVO${RST}\n"
        FTP_PID=""
    fi

    echo -e "  ${G}1)${RST} Iniciar servidor FTP rapido"
    echo -e "  ${G}2)${RST} Iniciar con configuracion personalizada"
    echo -e "  ${G}3)${RST} Conectar a un servidor FTP remoto"
    echo -e "  ${G}4)${RST} Detener servidor FTP"
    echo -e "  ${G}5)${RST} Ver logs"
    echo -e "  ${G}6)${RST} Estado del servicio"
    echo -e "  ${G}7)${RST} Instalar vsftpd (servidor permanente)"
    echo -e "  ${G}8)${RST} Salir"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1) ftp_rapido ;;
        2) ftp_personalizado ;;
        3) ftp_conectar ;;
        4) ftp_detener ;;
        5) ver_logs ;;
        6) ftp_estado ;;
        7) instalar_vsftpd ;;
        8) ftp_salir ;;
        *) echo -e "${R}  [!] Opcion no valida${RST}"; sleep 1; menu_principal ;;
    esac
}

# Iniciar FTP rapido (usuario anonimo, carpeta compartida)
ftp_rapido() {
    banner
    echo -e "${Y}  [*] Iniciando servidor FTP rapido...${RST}\n"

    FTP_USER="anonymous"
    FTP_PASS="(sin password)"
    FTP_PORT="2121"

    local log_file="$LOG_DIR/ftp_$(date +%Y%m%d_%H%M%S).log"

    # Usar pyftpdlib (viene con Python)
    python3 -m pyftpdlib -p "$FTP_PORT" -d "$FTP_SHARE" -w > "$log_file" 2>&1 &
    FTP_PID=$!
    sleep 1

    if kill -0 "$FTP_PID" 2>/dev/null; then
        local ip=$(get_ip)
        echo -e "${G}  ╔══════════════════════════════════════════╗${RST}"
        echo -e "${G}  ║       FTP ACTIVO - Modo Rapido           ║${RST}"
        echo -e "${G}  ╠══════════════════════════════════════════╣${RST}"
        echo -e "${G}  ║${RST}  Host:       ${C}$ip${RST}"
        echo -e "${G}  ║${RST}  Puerto:     ${C}$FTP_PORT${RST}"
        echo -e "${G}  ║${RST}  Usuario:    ${C}anonymous${RST}"
        echo -e "${G}  ║${RST}  Password:   ${C}(vacio)${RST}"
        echo -e "${G}  ║${RST}  Directorio: ${C}$FTP_SHARE${RST}"
        echo -e "${G}  ║${RST}  Lectura/Escritura: ${C}SI${RST}"
        echo -e "${G}  ╠══════════════════════════════════════════╣${RST}"
        echo -e "${G}  ║${RST}  ${DIM}Conexion: ftp://$ip:$FTP_PORT${RST}"
        echo -e "${G}  ╚══════════════════════════════════════════╝${RST}"
        echo -e "\n${Y}  Log: $log_file${RST}"
    else
        echo -e "${R}  [!] Error al iniciar. Verifica que pyftpdlib este instalado:${RST}"
        echo -e "${R}      pip install pyftpdlib${RST}"
        FTP_PID=""
    fi

    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# FTP con configuracion personalizada
ftp_personalizado() {
    banner
    echo -e "${C}  Configuracion personalizada del servidor FTP${RST}\n"

    read -rp "  Puerto [2121]: " port
    FTP_PORT=${port:-2121}

    read -rp "  Directorio a compartir [$FTP_SHARE]: " dir
    dir=${dir:-$FTP_SHARE}
    mkdir -p "$dir"

    read -rp "  Usuario [moskov]: " user
    FTP_USER=${user:-moskov}

    read -rsp "  Password: " pass
    echo ""
    FTP_PASS=${pass:-"ftp1234"}

    read -rp "  Permitir escritura? (s/n) [s]: " writable
    writable=${writable:-s}

    local write_flag=""
    [[ "$writable" == "s" ]] && write_flag="-w"

    local log_file="$LOG_DIR/ftp_$(date +%Y%m%d_%H%M%S).log"

    echo -e "\n${Y}  [*] Iniciando servidor...${RST}"
    python3 -m pyftpdlib -p "$FTP_PORT" -u "$FTP_USER" -P "$FTP_PASS" -d "$dir" $write_flag > "$log_file" 2>&1 &
    FTP_PID=$!
    sleep 1

    if kill -0 "$FTP_PID" 2>/dev/null; then
        local ip=$(get_ip)
        echo -e "\n${G}  [+] Servidor FTP activo!${RST}"
        echo -e "  Host: ${C}$ip:$FTP_PORT${RST}"
        echo -e "  User: ${C}$FTP_USER${RST}"
        echo -e "  Dir:  ${C}$dir${RST}"
    else
        echo -e "${R}  [!] Error al iniciar el servidor.${RST}"
        FTP_PID=""
    fi

    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Conectar a FTP remoto
ftp_conectar() {
    banner
    echo -e "${C}  Conectar a servidor FTP remoto${RST}\n"

    read -rp "  Host (IP o dominio): " host
    read -rp "  Puerto [21]: " port
    port=${port:-21}
    read -rp "  Usuario [anonymous]: " user
    user=${user:-anonymous}

    echo -e "\n${Y}  [*] Conectando a $host:$port...${RST}\n"
    ftp -n "$host" "$port" <<EOF
user $user
ls
bye
EOF

    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Detener FTP
ftp_detener() {
    banner
    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        kill "$FTP_PID" 2>/dev/null
        wait "$FTP_PID" 2>/dev/null
        echo -e "${G}  [+] Servidor FTP detenido (PID: $FTP_PID).${RST}"
        FTP_PID=""
    else
        echo -e "${Y}  [*] No hay servidor FTP activo.${RST}"
    fi
    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Ver logs
ver_logs() {
    banner
    echo -e "${C}  Logs recientes:${RST}\n"
    local ultimo=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    if [[ -n "$ultimo" ]]; then
        tail -30 "$ultimo"
        echo -e "\n${DIM}  Archivo: $ultimo${RST}"
    else
        echo -e "${Y}  No hay logs disponibles.${RST}"
    fi
    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Estado
ftp_estado() {
    banner
    echo -e "${C}  Estado del servicio FTP${RST}\n"

    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        echo -e "  Estado:   ${G}ACTIVO${RST}"
        echo -e "  PID:      $FTP_PID"
        echo -e "  Puerto:   $FTP_PORT"
        echo -e "  Usuario:  $FTP_USER"
        echo -e "  IP:       $(get_ip)"
    else
        echo -e "  Estado:   ${R}INACTIVO${RST}"
    fi

    echo -e "\n  ${DIM}vsftpd:${RST}"
    systemctl is-active vsftpd 2>/dev/null || echo "  no instalado"

    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Instalar vsftpd
instalar_vsftpd() {
    banner
    echo -e "${Y}  [*] Instalando vsftpd...${RST}"
    echo -e "${DIM}  Requiere sudo${RST}\n"
    sudo apt install vsftpd -y
    echo -e "\n${G}  [+] vsftpd instalado.${RST}"
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

# Salir
ftp_salir() {
    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        echo -e "${Y}  [!] Servidor FTP sigue activo (PID: $FTP_PID)${RST}"
        read -rp "  Detener antes de salir? (s/n): " resp
        [[ "$resp" == "s" ]] && kill "$FTP_PID" 2>/dev/null
    fi
    echo -e "\n${G}  Hasta luego!${RST}\n"
    exit 0
}

# Inicio
menu_principal
