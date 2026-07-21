#!/bin/bash
# =============================================================================
# startfire.sh - Gestion de Firewall (UFW)
# Autor: Moskov
# Uso: startfire
# =============================================================================

G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# Verificar root
if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

get_ip() { hostname -I | awk '{print $1}'; }

pausa() {
    echo ""
    read -rp "  Presiona ENTER para continuar..." _
}

banner() {
    clear
    echo -e "${C}"
    echo "  ========================================================"
    echo "       GESTION DE FIREWALL - StartFirewall"
    echo "  ========================================================"
    echo "   Control de reglas de red, puertos y estado del sistema"
    echo "  ========================================================"
    echo -e "${RST}"
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

menu_principal() {
    banner
    echo -e "  ${DIM}IP Local: $(get_ip)${RST}"
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        echo -e "  ${G}[+] FIREWALL ACTIVO${RST}\n"
    else
        echo -e "  ${R}[-] FIREWALL INACTIVO${RST}\n"
    fi
    echo -e "  ${G}1)${RST} Activar Firewall (UFW)"
    echo -e "  ${G}2)${RST} Detener Firewall (UFW)"
    echo -e "  ${G}3)${RST} Ver Estado y Reglas Activas"
    echo -e "  ${G}4)${RST} Permitir Puerto (TCP/UDP)"
    echo -e "  ${G}5)${RST} Bloquear Puerto / Servicio"
    echo -e "  ${G}6)${RST} Denegar IP especifica"
    echo -e "  ${G}7)${RST} Eliminar Regla existente"
    echo -e "  ${G}8)${RST} Restablecer Configuracion (Reset)"
    echo -e "  ${G}9)${RST} Escaneo rapido de Puertos Abiertos Locales"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1) fw_activar ;;
        2) fw_detener ;;
        3) fw_estado ;;
        4) fw_permitir ;;
        5) fw_bloquear ;;
        6) fw_denegar_ip ;;
        7) fw_eliminar_regla ;;
        8) fw_reset ;;
        9) fw_escaneo_local ;;
        0) echo -e "\n${G}  Hasta luego!${RST}\n"; exit 0 ;;
        *) echo -e "${R}  [!] Opcion no valida${RST}"; sleep 1 ;;
    esac
    menu_principal
}

# =============================================================================
# FUNCIONES
# =============================================================================

fw_activar() {
    banner
    echo -e "${Y}  [*] Activando Firewall...${RST}\n"
    ufw --force enable
    echo -e "\n${G}  [+] Firewall activado.${RST}"
    pausa
}

fw_detener() {
    banner
    echo -e "${Y}  [*] Deteniendo Firewall...${RST}\n"
    ufw disable
    echo -e "\n${G}  [+] Firewall desactivado.${RST}"
    pausa
}

fw_estado() {
    banner
    echo -e "${C}  Estado y Reglas Activas${RST}\n"
    ufw status verbose 2>/dev/null | sed 's/^/  /'
    pausa
}

fw_permitir() {
    banner
    echo -e "${C}  Permitir Puerto${RST}\n"
    read -rp "  Numero de puerto: " puerto
    echo ""
    echo -e "  ${G}1)${RST} TCP"
    echo -e "  ${G}2)${RST} UDP"
    echo -e "  ${G}3)${RST} Ambos (TCP+UDP)"
    echo ""
    read -rp "  Protocolo: " proto

    case $proto in
        1)
            ufw allow "$puerto/tcp"
            echo -e "\n${G}  [+] Permitido: $puerto/tcp${RST}"
            ;;
        2)
            ufw allow "$puerto/udp"
            echo -e "\n${G}  [+] Permitido: $puerto/udp${RST}"
            ;;
        3)
            ufw allow "$puerto"
            echo -e "\n${G}  [+] Permitido: $puerto (tcp+udp)${RST}"
            ;;
        *)
            echo -e "${R}  [!] Protocolo invalido.${RST}"
            ;;
    esac
    pausa
}

fw_bloquear() {
    banner
    echo -e "${C}  Bloquear Puerto / Servicio${RST}\n"
    echo -e "  ${G}1)${RST} Bloquear por numero de puerto"
    echo -e "  ${G}2)${RST} Bloquear por nombre de servicio"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            read -rp "  Numero de puerto: " puerto
            echo -e "  ${G}1)${RST} TCP  ${G}2)${RST} UDP  ${G}3)${RST} Ambos"
            read -rp "  Protocolo: " proto
            case $proto in
                1) ufw deny "$puerto/tcp"; echo -e "\n${G}  [+] Bloqueado: $puerto/tcp${RST}" ;;
                2) ufw deny "$puerto/udp"; echo -e "\n${G}  [+] Bloqueado: $puerto/udp${RST}" ;;
                3) ufw deny "$puerto"; echo -e "\n${G}  [+] Bloqueado: $puerto (tcp+udp)${RST}" ;;
            esac
            ;;
        2)
            read -rp "  Nombre del servicio (ej: ssh, http, ftp): " svc
            ufw deny "$svc"
            echo -e "\n${G}  [+] Servicio '$svc' bloqueado.${RST}"
            ;;
    esac
    pausa
}

fw_denegar_ip() {
    banner
    echo -e "${C}  Denegar IP Especifica${RST}\n"
    read -rp "  IP a bloquear: " ip

    echo ""
    echo -e "  ${G}1)${RST} Denegar todo el trafico desde esa IP"
    echo -e "  ${G}2)${RST} Denegar solo un puerto especifico desde esa IP"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            ufw deny from "$ip"
            echo -e "\n${G}  [+] Todo el trafico de $ip denegado.${RST}"
            ;;
        2)
            read -rp "  Puerto a bloquear desde $ip: " puerto
            ufw deny from "$ip" to any port "$puerto"
            echo -e "\n${G}  [+] Trafico de $ip al puerto $puerto denegado.${RST}"
            ;;
    esac
    pausa
}

fw_eliminar_regla() {
    banner
    echo -e "${C}  Eliminar Regla Existente${RST}\n"
    echo -e "  ${B}Reglas actuales (numeradas):${RST}\n"
    ufw status numbered 2>/dev/null | sed 's/^/  /'
    echo ""
    read -rp "  Numero de regla a eliminar (0=cancelar): " num
    [[ "$num" == "0" || -z "$num" ]] && return

    echo -e "\n${Y}  [*] Eliminando regla #$num...${RST}"
    echo "y" | ufw delete "$num"
    echo -e "${G}  [+] Regla eliminada.${RST}"
    pausa
}

fw_reset() {
    banner
    echo -e "${C}  Restablecer Configuracion${RST}\n"
    echo -e "${R}  [!] ATENCION: Esto eliminara TODAS las reglas actuales.${RST}"
    echo -e "      El firewall quedara con la configuracion por defecto.\n"
    read -rp "  Confirmar reset? (s/n): " resp

    if [[ "$resp" == "s" || "$resp" == "S" ]]; then
        echo -e "\n${Y}  [*] Reseteando UFW...${RST}"
        ufw --force reset
        echo -e "${G}  [+] Firewall restablecido a valores por defecto.${RST}"
        echo -e "  ${DIM}Recuerda activarlo nuevamente (opcion 1).${RST}"
    else
        echo -e "\n  ${DIM}Operacion cancelada.${RST}"
    fi
    pausa
}

fw_escaneo_local() {
    banner
    echo -e "${C}  Escaneo Rapido de Puertos Abiertos Locales${RST}\n"
    echo -e "  ${B}Puertos en escucha (LISTEN):${RST}\n"

    if command -v ss &>/dev/null; then
        ss -tulnp 2>/dev/null | grep LISTEN | awk '{
            split($5, a, ":");
            port = a[length(a)];
            proc = $7;
            gsub(/users:\(\("|",pid.*/, "", proc);
            printf "  %-8s %-6s %-20s %s\n", $1, port, $5, proc
        }'
    elif command -v netstat &>/dev/null; then
        netstat -tulnp 2>/dev/null | grep LISTEN | sed 's/^/  /'
    else
        echo -e "  ${R}Ni ss ni netstat disponibles.${RST}"
    fi

    echo ""
    echo -e "  ${B}Resumen rapido:${RST}"
    local total=$(ss -tulnp 2>/dev/null | grep -c LISTEN)
    local tcp=$(ss -tlnp 2>/dev/null | grep -c LISTEN)
    local udp=$(ss -ulnp 2>/dev/null | grep -c LISTEN)
    echo -e "  Total en escucha: ${C}$total${RST} (TCP: $tcp | UDP: $udp)"
    pausa
}

# =============================================================================
# INICIO
# =============================================================================
menu_principal
