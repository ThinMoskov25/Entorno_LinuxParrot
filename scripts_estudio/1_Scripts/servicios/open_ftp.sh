#!/bin/bash
# =============================================================================
# open_ftp.sh - Gestor de servicios de red (FTP, SSH, Samba)
# Autor: Moskov
# Descripcion: Activa servicios de red temporales con credenciales generadas
#              automaticamente. Al salir, limpia usuarios y detiene servicios.
# =============================================================================

# Colores
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Verificar root
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${RED}  [!] Ejecuta como root: sudo bash $0${RESET}"
    exit 1
fi

banner() {
    clear
    echo -e "${CYAN}  ═══════════════════════════════════════${RESET}"
    echo -e "${CYAN}       Gestor de Servicios de Red${RESET}"
    echo -e "${CYAN}  ═══════════════════════════════════════${RESET}"
    echo ""
}

menu_principal() {
    banner
    echo -e "  ${GREEN}1)${RESET} Activar servicio FTP"
    echo -e "  ${GREEN}2)${RESET} Activar servicio SSH"
    echo -e "  ${GREEN}3)${RESET} Info de la estacion"
    echo -e "  ${GREEN}4)${RESET} Salir"
    echo ""
    read -rp "  Selecciona opcion: " opcion

    case $opcion in
        1) activar_ftp ;;
        2) activar_ssh ;;
        3) info_estacion ;;
        4) salir ;;
        *) echo -e "${RED}  [!] Opcion no valida${RESET}"; sleep 1; menu_principal ;;
    esac
}

activar_ftp() {
    banner
    echo -e "${YELLOW}  [*] Activando servicio FTP...${RESET}\n"

    # Generar credenciales temporales
    local ftp_user="uftp$(shuf -i 100-999 -n 1)"
    local ftp_pass="Pass$(shuf -i 1000-9999 -n 1)+"
    local conexiones_root="${HOME}/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios/FTP"
    mkdir -p "$conexiones_root"
    local ftp_dir="$conexiones_root/tmp_${ftp_user}"

    # Crear usuario y directorio
    useradd -m -d "$ftp_dir" -s /usr/sbin/nologin "$ftp_user" 2>/dev/null
    echo "$ftp_user:$ftp_pass" | chpasswd
    mkdir -p "$ftp_dir"
    chown "$ftp_user:$ftp_user" "$ftp_dir"
    chmod 700 "$ftp_dir"

    # Iniciar vsftpd
    systemctl start vsftpd 2>/dev/null || service vsftpd start 2>/dev/null

    # Obtener IP local
    local ip_local=$(hostname -I | awk '{print $1}')

    echo -e "${GREEN}  ╔══════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}  ║     SERVICIO FTP ACTIVO              ║${RESET}"
    echo -e "${GREEN}  ╠══════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}  ║${RESET}  Usuario:  ${CYAN}$ftp_user${RESET}"
    echo -e "${GREEN}  ║${RESET}  Password: ${CYAN}$ftp_pass${RESET}"
    echo -e "${GREEN}  ║${RESET}  Host:     ${CYAN}$ip_local${RESET}"
    echo -e "${GREEN}  ║${RESET}  Puerto:   ${CYAN}21${RESET}"
    echo -e "${GREEN}  ║${RESET}  Directorio: ${CYAN}$ftp_dir${RESET}"
    echo -e "${GREEN}  ╚══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}  Presiona ENTER para detener el servicio y limpiar...${RESET}"
    read

    # Limpiar
    systemctl stop vsftpd 2>/dev/null
    userdel -r "$ftp_user" 2>/dev/null
    rm -rf "$ftp_dir" 2>/dev/null
    echo -e "${GREEN}  [+] Servicio FTP detenido. Usuario eliminado.${RESET}"
    sleep 2
    menu_principal
}

activar_ssh() {
    banner
    echo -e "${YELLOW}  [*] Verificando servicio SSH...${RESET}\n"

    if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        echo -e "${GREEN}  [+] SSH ya esta activo.${RESET}"
    else
        systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null
        echo -e "${GREEN}  [+] SSH activado.${RESET}"
    fi

    local ip_local=$(hostname -I | awk '{print $1}')
    echo -e "  Host: ${CYAN}$ip_local${RESET}"
    echo -e "  Puerto: ${CYAN}22${RESET}"
    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

info_estacion() {
    banner
    echo -e "  ${CYAN}INFORMACION DEL SISTEMA${RESET}"
    echo -e "  ──────────────────────────────"
    echo -e "  Hostname:    $(hostname)"
    echo -e "  OS:          $(uname -o)"
    echo -e "  Kernel:      $(uname -r)"
    echo -e "  IP Local:    $(hostname -I | awk '{print $1}')"
    echo -e "  RAM:         $(free -h | awk 'NR==2 {print $3 "/" $2}')"
    echo -e "  Disco:       $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " usado)"}')"
    echo -e "  Fecha:       $(date '+%d/%m/%Y %H:%M:%S')"
    echo -e "  ──────────────────────────────"
    echo ""
    read -rp "  Presiona ENTER para volver al menu..." _
    menu_principal
}

salir() {
    echo -e "\n${GREEN}  [+] Hasta luego!${RESET}\n"
    exit 0
}

# Inicio
menu_principal
