#!/bin/bash
# =============================================================================
# gestionar_compartidos.sh - Gestor Samba v6.0
# Autor: Moskov | TUI ANSI Estatica
# Uso: sudo bash gestionar_compartidos.sh
# =============================================================================

# ─── TERMINAL ────────────────────────────────────────────────────────────────
export TERM="${TERM:-xterm-256color}"
[[ "$TERM" == "xterm-kitty" ]] && export TERM="xterm-256color"

# ─── COLORES ─────────────────────────────────────────────────────────────────
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# ─── ROOT ────────────────────────────────────────────────────────────────────
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${R}  [!] Requiere root: sudo compartidos${RST}"; exit 1
fi

# ─── CONSTANTES ──────────────────────────────────────────────────────────────
SHARE_BASE="/srv/samba/shares"
SMB_CONF="/etc/samba/smb.conf"
REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
LOG_FILE="$REAL_HOME/Desktop/${SUDO_USER:-$USER}/Ciberseguridad/4_Servicios/Conexiones_Servicios/Unidades_Compartidas/samba.log"
RESULTADO=""

mkdir -p "$SHARE_BASE" "$(dirname "$LOG_FILE")" 2>/dev/null
touch "$LOG_FILE" 2>/dev/null

# ─── UTILIDADES ──────────────────────────────────────────────────────────────
get_ip() { hostname -I 2>/dev/null | awk '{print $1}'; }
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null; }
limpiar() { printf '\033[H\033[J'; }

listar_shares() { grep -E "^\[" "$SMB_CONF" 2>/dev/null | grep -v "\[global\]" | tr -d '[]'; }

listar_usuarios_samba() {
    pdbedit -L 2>/dev/null | cut -d: -f1 | while read -r u; do
        [[ "$u" == "root" ]] && continue
        local uid=$(id -u "$u" 2>/dev/null)
        [[ -n "$uid" && "$uid" -ge 1000 ]] && echo "$u"
    done
}

get_share_attr() {
    sed -n "/^\[$1\]/,/^\[/p" "$SMB_CONF" 2>/dev/null | grep -i "^\s*$2" | sed 's/.*=\s*//' | xargs
}

# ─── TUI ─────────────────────────────────────────────────────────────────────
dibujar_cabecera() {
    local st="${R}OFF${RST}"
    systemctl is-active --quiet smbd 2>/dev/null && st="${G}ON${RST}"
    echo -e "${C}  ══════════════════════════════════════════════════════════${RST}"
    echo -e "${C}            GESTOR SAMBA - Unidades Compartidas${RST}"
    echo -e "${C}  ══════════════════════════════════════════════════════════${RST}"
    echo -e "  ${DIM}IP: $(get_ip) | smbd: ${RST}$st ${DIM}| $SHARE_BASE${RST}"
    echo -e "${C}  ──────────────────────────────────────────────────────────${RST}"
}

dibujar_menu() {
    echo ""
    echo -e "  ${G}1)${RST} Creacion Recomendada (asistida, 1 paso)"
    echo -e "  ${G}2)${RST} Crear Compartido (manual)"
    echo -e "  ${G}3)${RST} Crear Usuario Samba (manual)"
    echo -e "  ${G}4)${RST} Gestion y Modificacion"
    echo -e "  ${G}5)${RST} Ver Estado y Conexiones"
    echo -e "  ${G}6)${RST} Testear Conexion / Diagnostico"
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

# ─── INICIALIZAR SAMBA ───────────────────────────────────────────────────────
instalar_samba() {
    command -v smbd &>/dev/null || { apt-get update -qq >/dev/null 2>&1; apt-get install -y samba smbclient >/dev/null 2>&1; }
    groupadd -f sambashare 2>/dev/null

    if [[ ! -f "$SMB_CONF" ]] || ! grep -q "\[global\]" "$SMB_CONF" 2>/dev/null; then
        cat > "$SMB_CONF" <<'SMBEOF'
[global]
   workgroup = WORKGROUP
   server string = Samba File Server
   security = user
   invalid users = root
   log file = /var/log/samba/log.%m
   max log size = 1000
SMBEOF
    fi

    systemctl is-active --quiet smbd 2>/dev/null || { systemctl enable smbd nmbd >/dev/null 2>&1; systemctl start smbd nmbd >/dev/null 2>&1; }

    # Corregir [global] existente: limpiar directivas problematicas
    sed -i '/map to guest/d' "$SMB_CONF" 2>/dev/null
    sed -i '/guest account/d' "$SMB_CONF" 2>/dev/null
    sed -i '/usershare allow guests/d' "$SMB_CONF" 2>/dev/null
    sed -i '/client ntlmv2/d' "$SMB_CONF" 2>/dev/null
    sed -i '/lanman auth/d' "$SMB_CONF" 2>/dev/null
    sed -i '/ntlm auth/d' "$SMB_CONF" 2>/dev/null
    sed -i '/passdb backend/d' "$SMB_CONF" 2>/dev/null
    # Eliminar directivas globales restrictivas de Parrot default que bloquean shares
    sed -i '/^\s*read only = yes/d' "$SMB_CONF" 2>/dev/null
    sed -i '/^\s*create mask = 0700/d' "$SMB_CONF" 2>/dev/null
    sed -i '/^\s*directory mask = 0700/d' "$SMB_CONF" 2>/dev/null
    sed -i '/^\s*valid users = %S/d' "$SMB_CONF" 2>/dev/null
    # Asegurar invalid users = root
    grep -q "invalid users" "$SMB_CONF" 2>/dev/null || sed -i '/\[global\]/a\   invalid users = root' "$SMB_CONF"

    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        ufw allow 445/tcp >/dev/null 2>&1; ufw allow 139/tcp >/dev/null 2>&1
    fi
}

# ─── RECARGAR SAMBA ──────────────────────────────────────────────────────────
recargar_samba() {
    local out=$(testparm -s 2>&1)
    if [[ $? -ne 0 ]]; then
        RESULTADO+="  ${R}[ERR] testparm:${RST} $(echo "$out" | tail -1)\n"
        return 1
    fi
    systemctl restart smbd nmbd >/dev/null 2>&1
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        ufw allow 445/tcp >/dev/null 2>&1; ufw allow 139/tcp >/dev/null 2>&1
    fi
}

# ─── CREAR USUARIO SAMBA (auxiliar reutilizable) ─────────────────────────────
crear_usuario_samba() {
    local -n _ret=$1 2>/dev/null || true

    read -rp "  Nombre de usuario: " usr
    [[ -z "$usr" ]] && { RESULTADO+="  ${R}Nombre vacio${RST}\n"; return 1; }

    groupadd -f sambashare 2>/dev/null
    if ! id "$usr" &>/dev/null; then
        useradd -M -s /sbin/nologin -G sambashare "$usr" 2>/dev/null || \
        useradd -M -s /usr/sbin/nologin -G sambashare "$usr" 2>/dev/null
        RESULTADO+="  ${G}[+]${RST} Usuario '$usr' creado (nologin)\n"
    else
        usermod -aG sambashare "$usr" 2>/dev/null
        RESULTADO+="  ${DIM}  '$usr' existe, agregado a sambashare${RST}\n"
    fi

    local pass1="" pass2=""
    while true; do
        read -rsp "  Password: " pass1; echo ""
        read -rsp "  Confirmar: " pass2; echo ""
        [[ "$pass1" == "$pass2" && -n "$pass1" ]] && break
        echo -e "  ${R}No coinciden.${RST}"
    done

    echo "$usr:$pass1" | chpasswd 2>/dev/null
    (echo "$pass1"; echo "$pass1") | smbpasswd -a -s "$usr" 2>/dev/null
    smbpasswd -e "$usr" 2>/dev/null

    if pdbedit -L 2>/dev/null | grep -q "^$usr:"; then
        RESULTADO+="  ${G}[+]${RST} '$usr' en Samba ${G}[OK]${RST}\n"
    else
        RESULTADO+="  ${R}[!]${RST} Fallo registrando '$usr'\n"; return 1
    fi

    log "USER: $usr"
    if declare -n _ret 2>/dev/null; then _ret="$usr"; fi
}

# =============================================================================
# 1. CREACION RECOMENDADA (asistida, todo en 1 paso + test automatico)
# =============================================================================
creacion_recomendada() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Creacion Recomendada (Auto-configuracion) ──${RST}\n"
    echo -e "  ${DIM}Solo necesitas: nombre del compartido + usuario + password${RST}\n"
    RESULTADO=""

    # 1. Nombre del compartido
    read -rp "  Nombre del compartido: " nombre
    [[ -z "$nombre" ]] && { RESULTADO="  ${R}Nombre vacio${RST}"; return; }
    if grep -q "^\[$nombre\]" "$SMB_CONF" 2>/dev/null; then
        RESULTADO="  ${R}'$nombre' ya existe${RST}"; return
    fi

    # 2. Usuario y password
    read -rp "  Nombre de usuario: " usuario
    [[ -z "$usuario" ]] && { RESULTADO="  ${R}Usuario vacio${RST}"; return; }

    local pass1="" pass2=""
    while true; do
        read -rsp "  Password: " pass1; echo ""
        read -rsp "  Confirmar: " pass2; echo ""
        [[ "$pass1" == "$pass2" && -n "$pass1" ]] && break
        echo -e "  ${R}No coinciden.${RST}"
    done

    echo -e "\n  ${Y}[*] Configurando...${RST}\n"

    # a) Crear directorio
    local ruta="$SHARE_BASE/$nombre"
    mkdir -p "$ruta"
    RESULTADO+="  ${G}[1/6]${RST} Directorio: $ruta\n"

    # b) Crear usuario sistema + Samba
    groupadd -f sambashare 2>/dev/null
    if ! id "$usuario" &>/dev/null; then
        useradd -M -s /sbin/nologin -G sambashare "$usuario" 2>/dev/null || \
        useradd -M -s /usr/sbin/nologin -G sambashare "$usuario" 2>/dev/null
    else
        usermod -aG sambashare "$usuario" 2>/dev/null
    fi
    echo "$usuario:$pass1" | chpasswd 2>/dev/null
    (echo "$pass1"; echo "$pass1") | smbpasswd -a -s "$usuario" 2>/dev/null
    smbpasswd -e "$usuario" 2>/dev/null

    if pdbedit -L 2>/dev/null | grep -q "^$usuario:"; then
        RESULTADO+="  ${G}[2/6]${RST} Usuario '$usuario' en Samba ${G}[OK]${RST}\n"
    else
        RESULTADO+="  ${R}[2/6]${RST} FALLO usuario Samba\n"; return
    fi

    # c) Permisos FS: root:sambashare con setgid
    chown -R root:sambashare "$ruta"
    chmod -R 2775 "$ruta"
    usermod -aG sambashare "$usuario" 2>/dev/null
    RESULTADO+="  ${G}[3/6]${RST} Permisos: root:sambashare 2775\n"

    # d) Escribir smb.conf
    cat >> "$SMB_CONF" <<EOF

[$nombre]
   path = $ruta
   browseable = yes
   writable = yes
   read only = no
   valid users = @sambashare $usuario
   force group = sambashare
   create mask = 0775
   directory mask = 0775
EOF
    RESULTADO+="  ${G}[4/6]${RST} smb.conf actualizado\n"

    # e) Recargar + firewall
    if recargar_samba; then
        RESULTADO+="  ${G}[5/6]${RST} smbd reiniciado + puertos 445/139 OK\n"
    else
        RESULTADO+="  ${R}[5/6]${RST} Error al recargar samba\n"
    fi

    # f) Test automatico de conectividad
    sleep 1
    local test_out=$(smbclient "//127.0.0.1/$nombre" -U "$usuario%$pass1" -c "ls" 2>&1)
    if [[ $? -eq 0 ]]; then
        RESULTADO+="  ${G}[6/6]${RST} Test local: ${G}CONECTADO EXITOSAMENTE${RST}\n"
    else
        RESULTADO+="  ${R}[6/6]${RST} Test local: FALLO\n"
        RESULTADO+="  ${DIM}  $(echo "$test_out" | head -2)${RST}\n"
    fi

    RESULTADO+="\n  ${B}═══ LISTO PARA USAR ═══${RST}\n"
    RESULTADO+="  ${C}Windows:${RST}  \\\\\\\\$(get_ip)\\\\$nombre\n"
    RESULTADO+="  ${C}Linux:${RST}    smbclient //$(get_ip)/$nombre -U $usuario\n"
    RESULTADO+="  ${C}Montar:${RST}   mount -t cifs //$(get_ip)/$nombre /mnt -o username=$usuario,password=***\n"
    RESULTADO+="  ${DIM}  Usuario: $usuario | Password: (la que ingresaste)${RST}\n"

    log "RECOMENDADO: $nombre | user=$usuario | path=$ruta"
}

# =============================================================================
# 2. CREAR COMPARTIDO (manual)
# =============================================================================
crear_compartido() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Crear Compartido (manual) ──${RST}\n"
    RESULTADO=""

    read -rp "  Nombre: " nombre
    [[ -z "$nombre" ]] && { RESULTADO="  ${R}Nombre vacio${RST}"; return; }
    if grep -q "^\[$nombre\]" "$SMB_CONF" 2>/dev/null; then
        RESULTADO="  ${R}'$nombre' ya existe${RST}"; return
    fi

    local ruta="$SHARE_BASE/$nombre"
    read -rp "  Ruta [$ruta]: " rc; [[ -n "$rc" ]] && ruta="$rc"

    echo -e "\n  ${G}1)${RST} Con usuario (autenticado)"
    echo -e "  ${G}2)${RST} Acceso libre (guest)"
    read -rp "  Tipo [1]: " tipo; tipo="${tipo:-1}"

    mkdir -p "$ruta"

    case $tipo in
        2)
            chown -R nobody:nogroup "$ruta"; chmod -R 0777 "$ruta"
            cat >> "$SMB_CONF" <<EOF

[$nombre]
   path = $ruta
   browseable = yes
   writable = yes
   read only = no
   guest ok = yes
   public = yes
   force user = nobody
   force group = nogroup
   create mask = 0777
   directory mask = 0777
EOF
            RESULTADO+="  ${G}[+]${RST} '$nombre' (libre)\n"
            ;;
        *)
            echo ""
            local usuario=""
            crear_usuario_samba usuario
            [[ -z "$usuario" ]] && { RESULTADO+="  ${R}Cancelado${RST}\n"; rm -rf "$ruta"; return; }
            chown -R root:sambashare "$ruta"; chmod -R 2775 "$ruta"
            cat >> "$SMB_CONF" <<EOF

[$nombre]
   path = $ruta
   browseable = yes
   writable = yes
   read only = no
   guest ok = no
   valid users = @sambashare $usuario
   force group = sambashare
   create mask = 0775
   directory mask = 0775
EOF
            RESULTADO+="  ${G}[+]${RST} '$nombre' | User: $usuario\n"
            ;;
    esac
    recargar_samba
    RESULTADO+="  ${C}Windows:${RST} \\\\\\\\$(get_ip)\\\\$nombre\n"
    log "SHARE: $nombre"
}

# =============================================================================
# 3. CREAR USUARIO SAMBA (standalone)
# =============================================================================
crear_usuario() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Crear Usuario Samba ──${RST}\n"
    RESULTADO=""
    local u=""; crear_usuario_samba u
}

# =============================================================================
# 4. GESTION Y MODIFICACION (submenu unificado)
# =============================================================================
gestion_modificacion() {
    while true; do
        limpiar; dibujar_cabecera
        echo -e "\n  ${B}── Gestion y Modificacion ──${RST}\n"
        echo -e "  ${G}1)${RST} Agregar usuario a compartido"
        echo -e "  ${G}2)${RST} Editar compartido"
        echo -e "  ${G}3)${RST} Editar usuario"
        echo -e "  ${G}4)${RST} Eliminar compartido"
        echo -e "  ${G}5)${RST} Eliminar usuario"
        echo -e "  ${R}6)${RST} ELIMINAR TODOS (compartidos + usuarios)"
        echo -e "  ${G}0)${RST} Volver al menu principal"
        echo ""
        if [[ -n "$RESULTADO" ]]; then dibujar_resultado; fi
        read -rp "  Opcion: " gopt
        RESULTADO=""
        case $gopt in
            1) sub_agregar_usuario ;; 2) sub_editar_compartido ;;
            3) sub_editar_usuario ;; 4) sub_eliminar_compartido ;;
            5) sub_eliminar_usuario ;; 6) sub_eliminar_todos ;;
            0) return ;;
            *) RESULTADO="  ${R}Invalido${RST}" ;;
        esac
    done
}

# --- Agregar usuario a compartido ---
sub_agregar_usuario() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Agregar Usuario a Compartido ──${RST}\n"

    local shares=$(listar_shares)
    [[ -z "$shares" ]] && { RESULTADO="  ${Y}No hay compartidos${RST}"; return; }

    local i=1; declare -a lista
    while IFS= read -r s; do
        echo -e "  ${G}$i)${RST} $s ${DIM}[$(get_share_attr "$s" "valid users")]${RST}"
        lista[$i]="$s"; ((i++))
    done <<< "$shares"
    echo ""; read -rp "  Compartido: " sel
    local target="${lista[$sel]}"
    [[ -z "$target" ]] && { RESULTADO="  ${R}Invalido${RST}"; return; }

    echo -e "\n  ${G}1)${RST} Crear nuevo  ${G}2)${RST} Existente"
    read -rp "  Opcion: " uopt
    local usuario=""
    case $uopt in
        1) crear_usuario_samba usuario ;;
        2)
            local ex=$(listar_usuarios_samba)
            [[ -n "$ex" ]] && echo -e "  ${DIM}Disponibles: $ex${RST}"
            read -rp "  Nombre: " usuario
            if ! pdbedit -L 2>/dev/null | grep -q "^$usuario:"; then
                RESULTADO="  ${R}'$usuario' no existe en Samba${RST}"; return
            fi ;;
    esac
    [[ -z "$usuario" ]] && return

    usermod -aG sambashare "$usuario" 2>/dev/null
    local cur=$(get_share_attr "$target" "valid users")
    if echo "$cur" | grep -qw "$usuario"; then
        RESULTADO="  ${Y}'$usuario' ya tiene acceso${RST}"; return
    fi
    if [[ -n "$cur" ]]; then
        sed -i "/^\[$target\]/,/^\[/{s/valid users = .*/valid users = $cur $usuario/}" "$SMB_CONF"
    else
        sed -i "/^\[$target\]/a\\   valid users = @sambashare $usuario" "$SMB_CONF"
    fi
    local sp=$(get_share_attr "$target" "path")
    [[ -n "$sp" && -d "$sp" ]] && { chown -R root:sambashare "$sp"; chmod -R 2775 "$sp"; }
    recargar_samba
    RESULTADO="  ${G}[+]${RST} '$usuario' -> '$target'\n  ${DIM}valid users: $(get_share_attr "$target" "valid users")${RST}"
}

# --- Editar compartido ---
sub_editar_compartido() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Editar Compartido ──${RST}\n"

    local shares=$(listar_shares)
    [[ -z "$shares" ]] && { RESULTADO="  ${Y}No hay compartidos${RST}"; return; }

    local i=1; declare -a lista
    while IFS= read -r s; do echo -e "  ${G}$i)${RST} $s"; lista[$i]="$s"; ((i++)); done <<< "$shares"
    echo ""; read -rp "  Seleccionar: " sel
    local target="${lista[$sel]}"
    [[ -z "$target" ]] && { RESULTADO="  ${R}Invalido${RST}"; return; }

    echo -e "\n  ${DIM}$target: path=$(get_share_attr "$target" "path") | users=$(get_share_attr "$target" "valid users")${RST}"
    echo -e "\n  ${G}1)${RST} Cambiar ruta  ${G}2)${RST} Toggle lectura/escritura  ${G}3)${RST} Toggle guest"
    read -rp "  Opcion: " eopt

    case $eopt in
        1)
            read -rp "  Nueva ruta: " nr; [[ -z "$nr" ]] && return
            mkdir -p "$nr"; chown -R root:sambashare "$nr"; chmod -R 2775 "$nr"
            sed -i "/^\[$target\]/,/^\[/{s|path = .*|path = $nr|}" "$SMB_CONF"
            recargar_samba; RESULTADO="  ${G}[+]${RST} Ruta -> $nr" ;;
        2)
            local w=$(get_share_attr "$target" "writable")
            if [[ "$w" == "yes" ]]; then
                sed -i "/^\[$target\]/,/^\[/{s/writable = .*/writable = no/}" "$SMB_CONF"
                sed -i "/^\[$target\]/,/^\[/{s/read only = .*/read only = yes/}" "$SMB_CONF"
                recargar_samba; RESULTADO="  ${G}[+]${RST} '$target' -> solo lectura"
            else
                sed -i "/^\[$target\]/,/^\[/{s/writable = .*/writable = yes/}" "$SMB_CONF"
                sed -i "/^\[$target\]/,/^\[/{s/read only = .*/read only = no/}" "$SMB_CONF"
                recargar_samba; RESULTADO="  ${G}[+]${RST} '$target' -> lectura/escritura"
            fi ;;
        3)
            local g=$(get_share_attr "$target" "guest ok")
            if [[ "$g" == "yes" ]]; then
                sed -i "/^\[$target\]/,/^\[/{s/guest ok = .*/guest ok = no/}" "$SMB_CONF"
                recargar_samba; RESULTADO="  ${G}[+]${RST} Guest deshabilitado"
            else
                sed -i "/^\[$target\]/,/^\[/{s/guest ok = .*/guest ok = yes/}" "$SMB_CONF"
                recargar_samba; RESULTADO="  ${G}[+]${RST} Guest habilitado"
            fi ;;
    esac
}

# --- Editar usuario ---
sub_editar_usuario() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Editar Usuario ──${RST}\n"

    local users=$(listar_usuarios_samba)
    [[ -z "$users" ]] && { RESULTADO="  ${Y}No hay usuarios${RST}"; return; }

    local i=1; declare -a lista
    while IFS= read -r u; do echo -e "  ${G}$i)${RST} $u"; lista[$i]="$u"; ((i++)); done <<< "$users"
    echo ""; read -rp "  Seleccionar: " sel
    local target="${lista[$sel]}"
    [[ -z "$target" ]] && { RESULTADO="  ${R}Invalido${RST}"; return; }

    echo -e "\n  ${G}1)${RST} Cambiar password  ${G}2)${RST} Ver shares asignados"
    read -rp "  Opcion: " eopt

    case $eopt in
        1)
            local p1="" p2=""
            while true; do
                read -rsp "  Nueva password: " p1; echo ""
                read -rsp "  Confirmar: " p2; echo ""
                [[ "$p1" == "$p2" && -n "$p1" ]] && break
                echo -e "  ${R}No coinciden.${RST}"
            done
            echo "$target:$p1" | chpasswd 2>/dev/null
            (echo "$p1"; echo "$p1") | smbpasswd -s "$target" 2>/dev/null
            RESULTADO="  ${G}[+]${RST} Password de '$target' actualizada" ;;
        2)
            RESULTADO="  ${B}Shares con acceso para '$target':${RST}\n"
            local shares=$(listar_shares); local found=0
            while IFS= read -r s; do
                local vu=$(get_share_attr "$s" "valid users")
                if echo "$vu" | grep -qw "$target" || echo "$vu" | grep -q "@sambashare"; then
                    RESULTADO+="    ${G}●${RST} $s\n"; found=1
                fi
            done <<< "$shares"
            [[ $found -eq 0 ]] && RESULTADO+="    ${DIM}Ninguno${RST}\n" ;;
    esac
}

# --- Eliminar compartido ---
sub_eliminar_compartido() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Eliminar Compartido ──${RST}\n"

    local shares=$(listar_shares)
    [[ -z "$shares" ]] && { RESULTADO="  ${Y}No hay compartidos${RST}"; return; }

    local i=1; declare -a lista
    while IFS= read -r s; do
        echo -e "  ${R}$i)${RST} $s -> $(get_share_attr "$s" "path")"; lista[$i]="$s"; ((i++))
    done <<< "$shares"
    local total=$((i-1))
    echo -e "\n  ${R}A)${RST} ELIMINAR TODOS ($total)  ${G}0)${RST} Cancelar\n"
    read -rp "  Seleccion: " sel
    [[ "$sel" == "0" || -z "$sel" ]] && return

    if [[ "$sel" == "A" || "$sel" == "a" ]]; then
        read -rp "  Escribir SI: " c; [[ "$c" != "SI" ]] && { RESULTADO="  ${DIM}Cancelado${RST}"; return; }
        while IFS= read -r s; do
            local tp=$(get_share_attr "$s" "path")
            sed -i "/^\[$s\]/,/^$/d" "$SMB_CONF"
            [[ -n "$tp" && -d "$tp" ]] && rm -rf "$tp"
        done <<< "$shares"
        recargar_samba; RESULTADO="  ${G}[+]${RST} $total eliminados"
    else
        local t="${lista[$sel]}"; [[ -z "$t" ]] && { RESULTADO="  ${R}Invalido${RST}"; return; }
        local tp=$(get_share_attr "$t" "path")
        sed -i "/^\[$t\]/,/^$/d" "$SMB_CONF"
        [[ -n "$tp" && -d "$tp" ]] && { read -rp "  Borrar carpeta? (s/n): " d; [[ "$d" == "s" ]] && rm -rf "$tp"; }
        recargar_samba; RESULTADO="  ${G}[+]${RST} '$t' eliminado"
    fi
}

# --- Eliminar usuario ---
sub_eliminar_usuario() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${B}── Eliminar Usuario ──${RST}\n"

    local users=$(listar_usuarios_samba)
    [[ -z "$users" ]] && { RESULTADO="  ${Y}No hay usuarios${RST}"; return; }

    local i=1; declare -a lista
    while IFS= read -r u; do echo -e "  ${R}$i)${RST} $u"; lista[$i]="$u"; ((i++)); done <<< "$users"
    local total=$((i-1))
    echo -e "\n  ${R}A)${RST} ELIMINAR TODOS ($total)  ${G}0)${RST} Cancelar\n"
    read -rp "  Seleccion: " sel
    [[ "$sel" == "0" || -z "$sel" ]] && return

    if [[ "$sel" == "A" || "$sel" == "a" ]]; then
        read -rp "  Escribir SI: " c; [[ "$c" != "SI" ]] && { RESULTADO="  ${DIM}Cancelado${RST}"; return; }
        while IFS= read -r u; do smbpasswd -x "$u" 2>/dev/null; userdel "$u" 2>/dev/null; done <<< "$users"
        RESULTADO="  ${G}[+]${RST} $total usuarios eliminados"
    else
        local t="${lista[$sel]}"; [[ -z "$t" ]] && { RESULTADO="  ${R}Invalido${RST}"; return; }
        smbpasswd -x "$t" 2>/dev/null; userdel "$t" 2>/dev/null
        RESULTADO="  ${G}[+]${RST} '$t' eliminado"
    fi
}

# --- Eliminar TODOS (compartidos + usuarios) ---
sub_eliminar_todos() {
    limpiar; dibujar_cabecera
    echo -e "\n  ${R}══ ELIMINAR TODOS ══${RST}\n"
    echo -e "  ${R}[!] Esto eliminara TODOS los compartidos y TODOS los usuarios Samba.${RST}"
    echo -e "  ${R}    (excluyendo root y cuentas del sistema)${RST}\n"
    read -rp "  Estas seguro? Escribir SI para confirmar: " conf
    [[ "$conf" != "SI" ]] && { RESULTADO="  ${DIM}Cancelado${RST}"; return; }

    local count_shares=0 count_users=0

    # Eliminar todos los shares del smb.conf
    local shares=$(listar_shares)
    if [[ -n "$shares" ]]; then
        while IFS= read -r s; do
            local tp=$(get_share_attr "$s" "path")
            sed -i "/^\[$s\]/,/^$/d" "$SMB_CONF"
            [[ -n "$tp" && -d "$tp" ]] && rm -rf "$tp"
            ((count_shares++))
        done <<< "$shares"
    fi

    # Eliminar todos los usuarios Samba (excluyendo root/sistema)
    local users=$(listar_usuarios_samba)
    if [[ -n "$users" ]]; then
        while IFS= read -r u; do
            smbpasswd -x "$u" 2>/dev/null
            userdel "$u" 2>/dev/null
            ((count_users++))
        done <<< "$users"
    fi

    recargar_samba
    RESULTADO="  ${G}[+]${RST} Eliminados: $count_shares compartidos + $count_users usuarios"
    log "ELIMINAR TODOS: $count_shares shares, $count_users users"
}

# =============================================================================
# 5. VER ESTADO Y CONEXIONES
# =============================================================================
ver_estado() {
    RESULTADO=""
    systemctl is-active --quiet smbd 2>/dev/null && RESULTADO+="  Servicio: ${G}ACTIVO${RST}\n" || RESULTADO+="  Servicio: ${R}INACTIVO${RST}\n"
    RESULTADO+="  IP: ${C}$(get_ip)${RST}\n"
    if command -v ufw &>/dev/null; then
        local fw=$(ufw status 2>/dev/null | grep -c "445/tcp.*ALLOW")
        [[ $fw -gt 0 ]] && RESULTADO+="  Firewall: ${G}445+139 OK${RST}\n" || RESULTADO+="  Firewall: ${R}CERRADO${RST}\n"
    fi

    RESULTADO+="\n  ${B}Compartidos:${RST}\n"
    local shares=$(listar_shares)
    if [[ -n "$shares" ]]; then
        while IFS= read -r s; do
            local p=$(get_share_attr "$s" "path")
            local g=$(get_share_attr "$s" "guest ok")
            local v=$(get_share_attr "$s" "valid users")
            local m="auth"; [[ "$g" == "yes" ]] && m="libre"
            RESULTADO+="    ${G}●${RST} $s ${DIM}[$m] $p${RST}\n"
            [[ -n "$v" ]] && RESULTADO+="      ${DIM}Users: $v${RST}\n"
        done <<< "$shares"
    else RESULTADO+="    ${DIM}Ninguno${RST}\n"; fi

    RESULTADO+="\n  ${B}Usuarios Samba:${RST}\n"
    local users=$(listar_usuarios_samba)
    [[ -n "$users" ]] && { while IFS= read -r u; do RESULTADO+="    ${G}●${RST} $u\n"; done <<< "$users"; } || RESULTADO+="    ${DIM}Ninguno${RST}\n"

    RESULTADO+="\n  ${B}Conexiones activas:${RST}\n"
    local c=$(smbstatus --shares 2>/dev/null | tail -n +4 | grep -v "^-" | head -5)
    if [[ -n "$c" ]]; then
        RESULTADO+="$(echo "$c" | sed 's/^/    /')\n"
        # Mostrar rutas de shares con conexion activa
        RESULTADO+="\n  ${B}Rutas de acceso (copiar para uso):${RST}\n"
        while IFS= read -r s; do
            local p=$(get_share_attr "$s" "path")
            [[ -z "$p" ]] && continue
            RESULTADO+="    ${C}\\\\\\\\$(get_ip)\\\\$s${RST}  ->  ${G}$p${RST}\n"
        done <<< "$(echo "$c" | awk '{print $1}' | sort -u)"
    else
        RESULTADO+="    ${DIM}Ninguna${RST}\n"
    fi
}

# =============================================================================
# 6. TESTEAR CONEXION / DIAGNOSTICO
# =============================================================================
testear_conexion() {
    RESULTADO="  ${B}Diagnostico Samba:${RST}\n\n"
    local shares=$(listar_shares)
    [[ -z "$shares" ]] && { RESULTADO+="  ${Y}No hay compartidos${RST}"; return; }
    while IFS= read -r s; do
        local g=$(get_share_attr "$s" "guest ok")
        if [[ "$g" == "yes" ]]; then
            smbclient "//127.0.0.1/$s" -N -c "ls" &>/dev/null && RESULTADO+="  ${G}[OK]${RST} $s (guest)\n" || RESULTADO+="  ${R}[FAIL]${RST} $s\n"
        else
            RESULTADO+="  ${DIM}[--]${RST} $s (auth) -> smbclient //$(get_ip)/$s -U user\n"
        fi
    done <<< "$shares"

    # testparm
    RESULTADO+="\n  ${B}testparm:${RST} "
    testparm -s >/dev/null 2>&1 && RESULTADO+="${G}OK${RST}\n" || RESULTADO+="${R}ERRORES${RST}\n"

    # Puertos
    RESULTADO+="  ${B}Puerto 445:${RST} "
    ss -tlnp 2>/dev/null | grep -q ":445 " && RESULTADO+="${G}ESCUCHANDO${RST}\n" || RESULTADO+="${R}CERRADO${RST}\n"
}

# =============================================================================
# BUCLE PRINCIPAL
# =============================================================================
instalar_samba
RESULTADO=""

while true; do
    redibujar
    read -rp "  Opcion: " opt
    RESULTADO=""
    case $opt in
        1) creacion_recomendada ;;
        2) crear_compartido ;;
        3) crear_usuario ;;
        4) gestion_modificacion ;;
        5) ver_estado ;;
        6) testear_conexion ;;
        0) limpiar; echo -e "  ${G}Bye!${RST}"; exit 0 ;;
        *) RESULTADO="  ${R}Opcion invalida${RST}" ;;
    esac
done
