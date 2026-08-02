#!/bin/bash
# =============================================================================
# startfire.sh - Gestion de Firewall (UFW)
# Autor: Moskov | Interfaz: TUI estatica ANSI
# =============================================================================

# ─── FIX TERMINAL ────────────────────────────────────────────────────────────
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == "xterm-kitty" ]] && export TERM="xterm-256color"

# ─── COLORES ─────────────────────────────────────────────────────────────────
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# ─── VERIFICAR ROOT ──────────────────────────────────────────────────────────
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${R}  [!] Ejecuta con sudo: sudo startfire${RST}"
    exit 1
fi

RESULTADO=""

# ─── TUI ENGINE ──────────────────────────────────────────────────────────────
get_ip() { hostname -I | awk '{print $1}'; }
limpiar() { printf '\033[H\033[J'; }

dibujar_cabecera() {
    local estado="${R}INACTIVO${RST}"
    ufw status 2>/dev/null | grep -q "Status: active" && estado="${G}ACTIVO${RST}"
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "${C}            GESTION DE FIREWALL - UFW${RST}"
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "  ${DIM}IP: $(get_ip) | Firewall: ${RST}$estado"
    echo -e "${C}  ────────────────────────────────────────────────────────${RST}"
}

dibujar_menu() {
    echo ""
    echo -e "  ${G}1)${RST} Activar Firewall"
    echo -e "  ${G}2)${RST} Detener Firewall"
    echo -e "  ${G}3)${RST} Ver estado y reglas"
    echo -e "  ${G}4)${RST} Permitir puerto"
    echo -e "  ${G}5)${RST} Bloquear puerto/servicio"
    echo -e "  ${G}6)${RST} Denegar IP"
    echo -e "  ${G}7)${RST} Eliminar regla"
    echo -e "  ${G}8)${RST} Reset (restablecer todo)"
    echo -e "  ${G}9)${RST} Escaneo puertos locales"
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

fw_activar() {
    ufw --force enable >/dev/null 2>&1
    RESULTADO="  ${G}[+] Firewall ACTIVADO${RST}"
}

fw_detener() {
    ufw disable >/dev/null 2>&1
    RESULTADO="  ${G}[+] Firewall DESACTIVADO${RST}"
}

fw_estado() {
    RESULTADO="  ${B}Reglas activas:${RST}\n\n$(ufw status verbose 2>/dev/null | sed 's/^/  /')"
}

fw_permitir() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Permitir Puerto ──${RST}\n"
    read -rp "  Puerto: " puerto
    echo -e "  ${G}1)${RST} TCP  ${G}2)${RST} UDP  ${G}3)${RST} Ambos"
    read -rp "  Protocolo: " proto
    case $proto in
        1) ufw allow "$puerto/tcp" >/dev/null; RESULTADO="  ${G}[+] Permitido: $puerto/tcp${RST}" ;;
        2) ufw allow "$puerto/udp" >/dev/null; RESULTADO="  ${G}[+] Permitido: $puerto/udp${RST}" ;;
        3) ufw allow "$puerto" >/dev/null; RESULTADO="  ${G}[+] Permitido: $puerto${RST}" ;;
        *) RESULTADO="  ${R}Invalido${RST}" ;;
    esac
}

fw_bloquear() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Bloquear Puerto ──${RST}\n"
    echo -e "  ${G}1)${RST} Por numero  ${G}2)${RST} Por servicio"
    read -rp "  Opcion: " opt
    case $opt in
        1)
            read -rp "  Puerto: " puerto
            echo -e "  ${G}1)${RST} TCP  ${G}2)${RST} UDP  ${G}3)${RST} Ambos"
            read -rp "  Proto: " p
            case $p in
                1) ufw deny "$puerto/tcp" >/dev/null ;; 2) ufw deny "$puerto/udp" >/dev/null ;; 3) ufw deny "$puerto" >/dev/null ;;
            esac
            RESULTADO="  ${G}[+] Bloqueado: $puerto${RST}" ;;
        2)
            read -rp "  Servicio (ssh,http,ftp): " svc
            ufw deny "$svc" >/dev/null
            RESULTADO="  ${G}[+] '$svc' bloqueado${RST}" ;;
    esac
}

fw_denegar_ip() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Denegar IP ──${RST}\n"
    read -rp "  IP: " ip
    echo -e "  ${G}1)${RST} Todo trafico  ${G}2)${RST} Solo un puerto"
    read -rp "  Opcion: " opt
    case $opt in
        1) ufw deny from "$ip" >/dev/null; RESULTADO="  ${G}[+] IP $ip denegada${RST}" ;;
        2) read -rp "  Puerto: " p; ufw deny from "$ip" to any port "$p" >/dev/null; RESULTADO="  ${G}[+] $ip:$p denegado${RST}" ;;
    esac
}

fw_eliminar_regla() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Eliminar Regla ──${RST}\n"
    ufw status numbered 2>/dev/null | sed 's/^/  /'
    echo ""; read -rp "  Numero (0=cancelar): " num
    [[ "$num" == "0" || -z "$num" ]] && { RESULTADO=""; return; }
    echo "y" | ufw delete "$num" >/dev/null 2>&1
    RESULTADO="  ${G}[+] Regla #$num eliminada${RST}"
}

fw_reset() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${R}[!] Esto elimina TODAS las reglas.${RST}\n"
    read -rp "  Confirmar? (s/n): " r
    if [[ "$r" == "s" ]]; then
        ufw --force reset >/dev/null 2>&1
        RESULTADO="  ${G}[+] Firewall reseteado${RST}"
    else
        RESULTADO="  ${DIM}Cancelado${RST}"
    fi
}

fw_escaneo_local() {
    RESULTADO="  ${B}Puertos en LISTEN:${RST}\n\n"
    if command -v ss &>/dev/null; then
        RESULTADO+="$(ss -tulnp 2>/dev/null | grep LISTEN | awk '{printf "  %-6s %s\n", $1, $5}' | head -20)"
    else
        RESULTADO+="$(netstat -tulnp 2>/dev/null | grep LISTEN | sed 's/^/  /' | head -20)"
    fi
    local total=$(ss -tulnp 2>/dev/null | grep -c LISTEN)
    RESULTADO+="\n\n  ${DIM}Total: $total puertos${RST}"
}

# ─── BUCLE PRINCIPAL ─────────────────────────────────────────────────────────
while true; do
    redibujar
    read -rp "  Opcion: " opt
    RESULTADO=""
    case $opt in
        1) fw_activar ;; 2) fw_detener ;; 3) fw_estado ;;
        4) fw_permitir ;; 5) fw_bloquear ;; 6) fw_denegar_ip ;;
        7) fw_eliminar_regla ;; 8) fw_reset ;; 9) fw_escaneo_local ;;
        0) limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Invalido${RST}" ;;
    esac
done
