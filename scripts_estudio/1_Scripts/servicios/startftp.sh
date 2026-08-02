#!/bin/bash
# =============================================================================
# startftp - Gestor interactivo de servidor FTP
# Autor: Moskov | Interfaz: TUI estatica ANSI
# =============================================================================

# ─── FIX TERMINAL ────────────────────────────────────────────────────────────
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == "xterm-kitty" ]] && export TERM="xterm-256color"

# ─── COLORES ─────────────────────────────────────────────────────────────────
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# ─── VARIABLES ───────────────────────────────────────────────────────────────
CONEXIONES_ROOT="${HOME}/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios"
WORK_DIR="$CONEXIONES_ROOT/FTP"
LOG_DIR="$WORK_DIR/logs"
FTP_SHARE="$WORK_DIR/FTP_Share"
mkdir -p "$LOG_DIR" "$FTP_SHARE"

FTP_PID=""
FTP_USER=""
FTP_PORT="2121"
RESULTADO=""

# Auto-instalar pyftpdlib
if ! python3 -m pyftpdlib --help &>/dev/null 2>&1; then
    pip install pyftpdlib --break-system-packages 2>/dev/null || pip install pyftpdlib 2>/dev/null
fi

# ─── TUI ENGINE ──────────────────────────────────────────────────────────────
get_ip() { hostname -I | awk '{print $1}'; }
limpiar() { printf '\033[H\033[J'; }

dibujar_cabecera() {
    local estado="${R}INACTIVO${RST}"
    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        estado="${G}ACTIVO (PID:$FTP_PID | :$FTP_PORT)${RST}"
    else
        FTP_PID=""
    fi
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "${C}              SERVIDOR FTP - StartFTP${RST}"
    echo -e "${C}  ════════════════════════════════════════════════════════${RST}"
    echo -e "  ${DIM}IP: $(get_ip) | Estado: ${RST}$estado"
    echo -e "${C}  ────────────────────────────────────────────────────────${RST}"
}

dibujar_menu() {
    echo ""
    echo -e "  ${G}1)${RST} Iniciar FTP rapido (anonimo)"
    echo -e "  ${G}2)${RST} Iniciar personalizado (usuario+pass)"
    echo -e "  ${G}3)${RST} Conectar a FTP remoto"
    echo -e "  ${G}4)${RST} Detener servidor"
    echo -e "  ${G}5)${RST} Ver logs"
    echo -e "  ${G}6)${RST} Estado"
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

ftp_rapido() {
    FTP_USER="anonymous"
    FTP_PORT="2121"
    local log_file="$LOG_DIR/ftp_$(date +%Y%m%d_%H%M%S).log"

    python3 -m pyftpdlib -p "$FTP_PORT" -d "$FTP_SHARE" -w > "$log_file" 2>&1 &
    FTP_PID=$!; sleep 1

    if kill -0 "$FTP_PID" 2>/dev/null; then
        RESULTADO="  ${G}[+]${RST} FTP activo\n"
        RESULTADO+="  Host:    ${C}$(get_ip):$FTP_PORT${RST}\n"
        RESULTADO+="  User:    ${C}anonymous (sin pass)${RST}\n"
        RESULTADO+="  Dir:     ${C}$FTP_SHARE${RST}\n"
        RESULTADO+="  Conexion: ${C}ftp://$(get_ip):$FTP_PORT${RST}"
    else
        RESULTADO="  ${R}[!] Error al iniciar. Instala: pip install pyftpdlib${RST}"
        FTP_PID=""
    fi
}

ftp_personalizado() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── FTP Personalizado ──${RST}\n"

    read -rp "  Puerto [2121]: " port; FTP_PORT=${port:-2121}
    read -rp "  Directorio [$FTP_SHARE]: " dir; dir=${dir:-$FTP_SHARE}; mkdir -p "$dir"
    read -rp "  Usuario [moskov]: " user; FTP_USER=${user:-moskov}
    read -rsp "  Password: " pass; echo ""; pass=${pass:-ftp1234}

    local log_file="$LOG_DIR/ftp_$(date +%Y%m%d_%H%M%S).log"
    python3 -m pyftpdlib -p "$FTP_PORT" -u "$FTP_USER" -P "$pass" -d "$dir" -w > "$log_file" 2>&1 &
    FTP_PID=$!; sleep 1

    if kill -0 "$FTP_PID" 2>/dev/null; then
        RESULTADO="  ${G}[+]${RST} FTP activo\n"
        RESULTADO+="  Host: ${C}$(get_ip):$FTP_PORT${RST} | User: ${C}$FTP_USER${RST}\n"
        RESULTADO+="  Dir:  ${C}$dir${RST}"
    else
        RESULTADO="  ${R}[!] Error al iniciar${RST}"; FTP_PID=""
    fi
}

ftp_conectar() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Conectar a FTP Remoto ──${RST}\n"
    read -rp "  Host: " host
    read -rp "  Puerto [21]: " port; port=${port:-21}
    read -rp "  Usuario [anonymous]: " user; user=${user:-anonymous}
    echo -e "\n${Y}  [*] Conectando...${RST}\n"
    ftp -n "$host" "$port" <<EOF
user $user
ls
bye
EOF
    echo ""; read -rp "  ENTER para volver..." _
    RESULTADO=""
}

ftp_detener() {
    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        kill "$FTP_PID" 2>/dev/null; wait "$FTP_PID" 2>/dev/null
        RESULTADO="  ${G}[+]${RST} Servidor detenido (PID: $FTP_PID)"
        FTP_PID=""
    else
        RESULTADO="  ${Y}No hay servidor activo${RST}"
    fi
}

ver_logs() {
    local ultimo=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    if [[ -n "$ultimo" ]]; then
        RESULTADO="  ${B}Ultimo log:${RST} $ultimo\n\n$(tail -15 "$ultimo" | sed 's/^/  /')"
    else
        RESULTADO="  ${DIM}No hay logs${RST}"
    fi
}

ftp_estado() {
    RESULTADO=""
    if [[ -n "$FTP_PID" ]] && kill -0 "$FTP_PID" 2>/dev/null; then
        RESULTADO+="  Estado:  ${G}ACTIVO${RST}\n"
        RESULTADO+="  PID:     $FTP_PID\n"
        RESULTADO+="  Puerto:  $FTP_PORT\n"
        RESULTADO+="  Usuario: $FTP_USER\n"
        RESULTADO+="  IP:      $(get_ip)"
    else
        RESULTADO+="  Estado: ${R}INACTIVO${RST}"
    fi
}

# ─── BUCLE PRINCIPAL ─────────────────────────────────────────────────────────
RESULTADO=""
while true; do
    redibujar
    read -rp "  Opcion: " opt
    RESULTADO=""
    case $opt in
        1) ftp_rapido ;; 2) ftp_personalizado ;; 3) ftp_conectar ;;
        4) ftp_detener ;; 5) ver_logs ;; 6) ftp_estado ;;
        0)
            [[ -n "$FTP_PID" ]] && kill "$FTP_PID" 2>/dev/null
            limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Invalido${RST}" ;;
    esac
done
