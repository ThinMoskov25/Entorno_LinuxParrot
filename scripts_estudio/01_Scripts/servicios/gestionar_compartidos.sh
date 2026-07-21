#!/bin/bash
# =============================================================================
# gestionar_compartidos.sh - Gestor de Unidades Compartidas (SMB/NFS/SSHFS)
# Autor: Moskov
# Descripcion: Aplicacion TUI interactiva para gestionar unidades compartidas.
#              Soporta montar/desmontar, crear compartidos, diagnostico,
#              cuotas, respaldos, monitoreo y mantenimiento.
# Uso: sudo bash gestionar_compartidos.sh
# =============================================================================

# --- Correccion de terminal ---
export TERM=${TERM:-xterm-256color}
if ! infocmp "$TERM" &>/dev/null 2>&1; then export TERM=xterm-256color; fi

# --- Verificar root ---
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Este script requiere root: sudo bash $0"
    exit 1
fi

# --- Rutas de trabajo (Estandar: Conexiones Servicios) ---
CONEXIONES_ROOT="/home/moskov/Desktop/Moskov/Ciberseguridad/04_Servicios/Conexiones Servicios"
WORK_DIR="$CONEXIONES_ROOT/Unidades_Compartidas"
LOG_DIR="$WORK_DIR/logs"
CRED_DIR="$WORK_DIR/credenciales"
BACKUP_DIR="$WORK_DIR/backups"
MOUNT_DIR="$WORK_DIR/montajes"
CONF_DIR="$WORK_DIR/configuracion"
TEMP_USERS_FILE="$CONF_DIR/usuarios_temporales.conf"
AUDIT_LOG="$LOG_DIR/auditoria.log"

mkdir -p "$LOG_DIR" "$CRED_DIR" "$BACKUP_DIR" "$MOUNT_DIR" "$CONF_DIR"
touch "$AUDIT_LOG"
[[ ! -f "$TEMP_USERS_FILE" ]] && touch "$TEMP_USERS_FILE"

# --- Dimensiones TUI ---
LINES=$(tput lines)
COLS=$(tput cols)
H=$((LINES - 4))
W=$((COLS - 10))
[[ $H -lt 20 ]] && H=20
[[ $W -lt 60 ]] && W=70
MH=$((H - 8))

# =============================================================================
# FUNCIONES UTILITARIAS
# =============================================================================

log_audit() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AUDIT_LOG"
}

get_ip() { hostname -I | awk '{print $1}'; }

check_port() {
    local host="$1" port="$2" timeout="${3:-3}"
    timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
    return $?
}

verificar_dependencia() {
    local cmd="$1" pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        whiptail --infobox "Instalando $pkg..." 5 40
        apt-get install -y "$pkg" &>/dev/null
    fi
}

# Muestra progreso con gauge
mostrar_progreso() {
    local titulo="$1" mensaje="$2" duracion="${3:-3}"
    local i=0
    (
        while [[ $i -le 100 ]]; do
            echo $i
            sleep "$(echo "scale=2; $duracion/100" | bc 2>/dev/null || echo 0.03)"
            ((i+=2))
        done
    ) | whiptail --title "$titulo" --gauge "$mensaje" 7 50 0
}

# Muestra resultado en scrollable msgbox
mostrar_resultado() {
    local titulo="$1" contenido="$2"
    whiptail --title "$titulo" --scrolltext --msgbox "$contenido" $H $W
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

menu_principal() {
    while true; do
        local ip_local=$(get_ip)
        local opcion
        opcion=$(whiptail --title "GESTOR DE UNIDADES COMPARTIDAS" \
            --menu "\n  IP Local: $ip_local\n  Ruta: $WORK_DIR\n" $H $W $MH \
            "1" "Escanear red (descubrir SMB/NFS)" \
            "2" "Conectar a unidad compartida (SMB/NFS/SSHFS)" \
            "3" "Persistencia (automontaje fstab/systemd)" \
            "4" "Listar y desmontar unidades activas" \
            "---" "─────────────────────────────────────" \
            "5" "Crear nueva unidad compartida (Samba/NFS)" \
            "6" "Gestionar usuarios temporales" \
            "---2" "─────────────────────────────────────" \
            "7" "Diagnostico y prueba de conectividad" \
            "---3" "─────────────────────────────────────" \
            "8" "Gestion de espacio y cuotas" \
            "9" "Monitoreo e historial" \
            "10" "Respaldos y restauracion" \
            "11" "Mantenimiento (forzar desmontaje / rsync)" \
            3>&1 1>&2 2>&3)

        local ret=$?
        [[ $ret -ne 0 ]] && exit 0

        case $opcion in
            1) escanear_red ;;
            2) conectar_unidad ;;
            3) persistencia_montaje ;;
            4) listar_desmontar ;;
            5) crear_compartido ;;
            6) gestionar_usuarios_temp ;;
            7) diagnostico ;;
            8) gestion_cuotas ;;
            9) monitoreo_historial ;;
            10) respaldos_restauracion ;;
            11) mantenimiento ;;
        esac
    done
}

# =============================================================================
# A. GESTION DE CONEXIONES (CLIENTE)
# =============================================================================

# --- 1. Escanear red ---
escanear_red() {
    verificar_dependencia "nmap" "nmap"
    verificar_dependencia "smbclient" "smbclient"

    local subnet
    subnet=$(ip route | grep -v default | grep "src $(get_ip)" | awk '{print $1}' | head -1)
    [[ -z "$subnet" ]] && subnet="$(get_ip | sed 's/\.[0-9]*$/.0\/24/')"

    local opcion
    opcion=$(whiptail --title "ESCANEO DE RED" \
        --menu "\nSubred detectada: $subnet\n" $H $W 4 \
        "1" "Escanear recursos SMB (puerto 445)" \
        "2" "Escanear recursos NFS (puerto 2049)" \
        "3" "Escaneo completo (SMB + NFS + SSHFS)" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    local resultado=""

    case $opcion in
        1)
            mostrar_progreso "Escaneo SMB" "Escaneando puerto 445 en $subnet..." 4 &
            local pg_pid=$!
            resultado=$(nmap -p 445 --open -oG - "$subnet" 2>/dev/null | grep "445/open" | awk '{print $2}' | while read -r host; do
                echo "Host: $host"
                smbclient -L "//$host" -N 2>/dev/null | grep -i "disk\|share" | sed 's/^/  /'
                echo ""
            done)
            kill $pg_pid 2>/dev/null; wait $pg_pid 2>/dev/null
            [[ -z "$resultado" ]] && resultado="No se encontraron recursos SMB en $subnet"
            log_audit "Escaneo SMB en $subnet"
            ;;
        2)
            verificar_dependencia "showmount" "nfs-common"
            mostrar_progreso "Escaneo NFS" "Escaneando puerto 2049 en $subnet..." 4 &
            local pg_pid=$!
            resultado=$(nmap -p 2049 --open -oG - "$subnet" 2>/dev/null | grep "2049/open" | awk '{print $2}' | while read -r host; do
                echo "Host NFS: $host"
                showmount -e "$host" 2>/dev/null | tail -n +2 | sed 's/^/  /'
                echo ""
            done)
            kill $pg_pid 2>/dev/null; wait $pg_pid 2>/dev/null
            [[ -z "$resultado" ]] && resultado="No se encontraron exportaciones NFS en $subnet"
            log_audit "Escaneo NFS en $subnet"
            ;;
        3)
            mostrar_progreso "Escaneo Completo" "Escaneando puertos 22, 445, 2049 en $subnet..." 6 &
            local pg_pid=$!
            resultado=$(nmap -p 22,445,2049 --open "$subnet" 2>/dev/null | grep -E "Nmap scan|open")
            kill $pg_pid 2>/dev/null; wait $pg_pid 2>/dev/null
            [[ -z "$resultado" ]] && resultado="No se encontraron hosts con puertos abiertos en $subnet"
            log_audit "Escaneo completo en $subnet"
            ;;
    esac

    mostrar_resultado "Resultado del Escaneo" "$resultado"
}

# --- 2. Conectar a unidad compartida ---
conectar_unidad() {
    local tipo
    tipo=$(whiptail --title "CONECTAR A UNIDAD" \
        --menu "\nSelecciona el tipo de recurso a montar:\n" $H $W 4 \
        "SMB" "Montar recurso Samba/CIFS (puerto 445)" \
        "NFS" "Montar recurso NFS (puerto 2049)" \
        "SSHFS" "Montar recurso SSHFS (puerto 22)" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $tipo in
        SMB) montar_smb ;;
        NFS) montar_nfs ;;
        SSHFS) montar_sshfs ;;
    esac
}

montar_smb() {
    verificar_dependencia "mount.cifs" "cifs-utils"

    local host
    host=$(whiptail --title "MONTAR SMB" --inputbox "Host (IP o nombre):" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$host" ]] && return

    # Validar puerto
    whiptail --infobox "Verificando puerto 445 en $host..." 5 45
    if ! check_port "$host" 445; then
        whiptail --title "ERROR" --msgbox "Puerto 445 no accesible en $host.\nConexion abortada." 8 50
        log_audit "FALLO: SMB puerto 445 cerrado en $host"
        return
    fi

    local share
    share=$(whiptail --title "MONTAR SMB" --inputbox "Nombre del recurso compartido:" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$share" ]] && return

    local user
    user=$(whiptail --title "MONTAR SMB" --inputbox "Usuario (vacio = guest):" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    local mount_name="${host}_${share}"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    if [[ -n "$user" ]]; then
        local pass
        pass=$(whiptail --title "MONTAR SMB" --passwordbox "Contrasena para $user:" 8 50 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return

        # Guardar credenciales seguras
        local cred_file="$CRED_DIR/smb_${mount_name}.cred"
        echo -e "username=$user\npassword=$pass" > "$cred_file"
        chmod 600 "$cred_file"

        mount -t cifs "//$host/$share" "$mount_point" -o "credentials=$cred_file,iocharset=utf8,vers=3.0" 2>/dev/null
    else
        mount -t cifs "//$host/$share" "$mount_point" -o "guest,iocharset=utf8,vers=3.0" 2>/dev/null
    fi

    if mountpoint -q "$mount_point" 2>/dev/null; then
        whiptail --title "EXITO" --msgbox "Montado exitosamente:\n\n//$host/$share\n-> $mount_point" 10 55
        log_audit "MONTAJE SMB: //$host/$share en $mount_point (usuario: ${user:-guest})"
    else
        whiptail --title "ERROR" --msgbox "No se pudo montar. Verifica credenciales y recurso." 8 55
        rmdir "$mount_point" 2>/dev/null
    fi
}

montar_nfs() {
    verificar_dependencia "showmount" "nfs-common"

    local host
    host=$(whiptail --title "MONTAR NFS" --inputbox "Host (IP):" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$host" ]] && return

    whiptail --infobox "Verificando puerto 2049 en $host..." 5 45
    if ! check_port "$host" 2049; then
        whiptail --title "ERROR" --msgbox "Puerto 2049 no accesible en $host.\nConexion abortada." 8 50
        log_audit "FALLO: NFS puerto 2049 cerrado en $host"
        return
    fi

    # Mostrar exportaciones disponibles
    local exports
    exports=$(showmount -e "$host" 2>/dev/null | tail -n +2)
    [[ -z "$exports" ]] && exports="(no se pudieron listar exportaciones)"

    local remote_path
    remote_path=$(whiptail --title "MONTAR NFS" --inputbox "Exportaciones en $host:\n$exports\n\nRuta remota a montar:" 14 60 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$remote_path" ]] && return

    local mount_name="${host}_$(basename "$remote_path")"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    mostrar_progreso "Montando NFS" "Conectando a $host:$remote_path..." 2
    mount -t nfs "$host:$remote_path" "$mount_point" -o rw,sync 2>/dev/null

    if mountpoint -q "$mount_point" 2>/dev/null; then
        whiptail --title "EXITO" --msgbox "NFS montado:\n$host:$remote_path\n-> $mount_point" 9 55
        log_audit "MONTAJE NFS: $host:$remote_path en $mount_point"
    else
        whiptail --title "ERROR" --msgbox "Error al montar NFS.\nVerifica permisos de exportacion." 8 50
        rmdir "$mount_point" 2>/dev/null
    fi
}

montar_sshfs() {
    verificar_dependencia "sshfs" "sshfs"

    local host
    host=$(whiptail --title "MONTAR SSHFS" --inputbox "Host (IP):" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$host" ]] && return

    whiptail --infobox "Verificando puerto 22 en $host..." 5 45
    if ! check_port "$host" 22; then
        whiptail --title "ERROR" --msgbox "Puerto 22 no accesible en $host.\nConexion abortada." 8 50
        log_audit "FALLO: SSHFS puerto 22 cerrado en $host"
        return
    fi

    local user
    user=$(whiptail --title "MONTAR SSHFS" --inputbox "Usuario remoto:" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$user" ]] && return

    local remote_path
    remote_path=$(whiptail --title "MONTAR SSHFS" --inputbox "Ruta remota (ej: /home/user/shared):" 8 55 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$remote_path" ]] && return

    local mount_name="${host}_$(basename "$remote_path")"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    # SSHFS requiere interaccion para password - usar terminal
    clear
    echo "Conectando SSHFS: $user@$host:$remote_path"
    echo "Se solicitara la contrasena SSH..."
    echo ""
    sshfs "$user@$host:$remote_path" "$mount_point" -o allow_other,reconnect,ServerAliveInterval=15

    if mountpoint -q "$mount_point" 2>/dev/null; then
        whiptail --title "EXITO" --msgbox "SSHFS montado:\n$user@$host:$remote_path\n-> $mount_point" 9 55
        log_audit "MONTAJE SSHFS: $user@$host:$remote_path en $mount_point"
    else
        whiptail --title "ERROR" --msgbox "Error al montar SSHFS." 7 40
        rmdir "$mount_point" 2>/dev/null
    fi
}

# --- 3. Persistencia (Automontaje) ---
persistencia_montaje() {
    local montajes_activos
    montajes_activos=$(mount | grep "$MOUNT_DIR" 2>/dev/null)

    if [[ -z "$montajes_activos" ]]; then
        whiptail --title "PERSISTENCIA" --msgbox "No hay montajes activos.\nConecta primero una unidad (opcion 2)." 8 50
        return
    fi

    # Construir lista para radiolist
    local items=()
    local i=1
    while IFS= read -r line; do
        local src=$(echo "$line" | awk '{print $1}')
        local dst=$(echo "$line" | awk '{print $3}')
        local type=$(echo "$line" | awk '{print $5}')
        items+=("$i" "$src -> $dst [$type]" "OFF")
        ((i++))
    done <<< "$montajes_activos"

    local sel
    sel=$(whiptail --title "PERSISTENCIA - Seleccionar montaje" \
        --radiolist "\nSelecciona el montaje a hacer persistente:\n" $H $W $MH \
        "${items[@]}" 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$sel" ]] && return

    local selected
    selected=$(echo "$montajes_activos" | sed -n "${sel}p")
    local src=$(echo "$selected" | awk '{print $1}')
    local dst=$(echo "$selected" | awk '{print $3}')
    local type=$(echo "$selected" | awk '{print $5}')

    local metodo
    metodo=$(whiptail --title "PERSISTENCIA - Metodo" \
        --menu "\nMetodo de automontaje:\n" 12 55 2 \
        "fstab" "Agregar a /etc/fstab" \
        "systemd" "Crear unidad systemd.mount" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $metodo in
        fstab)
            local fstab_entry=""
            local cred_file="$CRED_DIR/smb_$(basename "$dst").cred"
            if [[ "$type" == "cifs" && -f "$cred_file" ]]; then
                fstab_entry="$src $dst cifs credentials=$cred_file,iocharset=utf8,vers=3.0,_netdev 0 0"
            elif [[ "$type" == "nfs" || "$type" == "nfs4" ]]; then
                fstab_entry="$src $dst nfs rw,sync,_netdev 0 0"
            elif [[ "$type" == "fuse.sshfs" ]]; then
                fstab_entry="$src $dst fuse.sshfs _netdev,allow_other,reconnect,IdentityFile=/root/.ssh/id_ed25519 0 0"
            fi

            if [[ -n "$fstab_entry" ]]; then
                if grep -qF "$dst" /etc/fstab; then
                    whiptail --title "AVISO" --msgbox "Ya existe una entrada para este punto de montaje en fstab." 7 55
                else
                    echo "$fstab_entry" >> /etc/fstab
                    whiptail --title "EXITO" --msgbox "Entrada agregada a /etc/fstab:\n\n$fstab_entry" 10 70
                    log_audit "PERSISTENCIA fstab: $fstab_entry"
                fi
            fi
            ;;
        systemd)
            local unit_name=$(systemd-escape --path "$dst")
            local unit_file="/etc/systemd/system/${unit_name}.mount"
            cat > "$unit_file" <<EOF
[Unit]
Description=Montaje automatico $src
After=network-online.target
Wants=network-online.target

[Mount]
What=$src
Where=$dst
Type=$type
Options=_netdev

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload
            systemctl enable "${unit_name}.mount"
            whiptail --title "EXITO" --msgbox "Unidad systemd creada y habilitada:\n${unit_name}.mount" 8 55
            log_audit "PERSISTENCIA systemd: ${unit_name}.mount creado"
            ;;
    esac
}

# --- 4. Listar y Desmontar ---
listar_desmontar() {
    local montajes
    montajes=$(mount | grep "$MOUNT_DIR" 2>/dev/null)

    if [[ -z "$montajes" ]]; then
        whiptail --title "UNIDADES MONTADAS" --msgbox "No hay unidades montadas actualmente." 7 45
        return
    fi

    # Construir checklist
    local items=()
    local i=1
    while IFS= read -r line; do
        local src=$(echo "$line" | awk '{print $1}')
        local dst=$(echo "$line" | awk '{print $3}')
        local type=$(echo "$line" | awk '{print $5}')
        local uso=$(df -h "$dst" 2>/dev/null | awk 'NR==2{print $3 "/" $2}')
        items+=("$i" "[$type] $src (${uso:-N/A})" "OFF")
        ((i++))
    done <<< "$montajes"

    local seleccion
    seleccion=$(whiptail --title "DESMONTAR UNIDADES" \
        --checklist "\nSelecciona unidades a desmontar:\n(Espacio para marcar, Enter para confirmar)\n" $H $W $MH \
        "${items[@]}" 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$seleccion" ]] && return

    # Confirmar
    if ! whiptail --title "CONFIRMAR" --yesno "Desmontar las unidades seleccionadas?" 7 45; then
        return
    fi

    local resultado=""
    for num in $seleccion; do
        num=$(echo "$num" | tr -d '"')
        local mp=$(echo "$montajes" | sed -n "${num}p" | awk '{print $3}')
        if [[ -n "$mp" ]]; then
            umount "$mp" 2>/dev/null
            if ! mountpoint -q "$mp" 2>/dev/null; then
                rmdir "$mp" 2>/dev/null
                resultado+="OK: $mp desmontado\n"
                log_audit "DESMONTAJE: $mp"
            else
                resultado+="FALLO: $mp no se pudo desmontar\n"
            fi
        fi
    done

    mostrar_resultado "Resultado" "$resultado"
}

# =============================================================================
# B. CONFIGURACION DE COMPARTIDOS (SERVIDOR)
# =============================================================================

# --- 5. Crear compartido ---
crear_compartido() {
    local tipo
    tipo=$(whiptail --title "CREAR COMPARTIDO" \
        --menu "\nTipo de compartido a crear:\n" 12 55 2 \
        "SAMBA" "Crear compartido Samba (SMB)" \
        "NFS" "Crear compartido NFS" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $tipo in
        SAMBA) crear_samba ;;
        NFS) crear_nfs ;;
    esac
}

crear_samba() {
    verificar_dependencia "smbd" "samba"

    local share_name
    share_name=$(whiptail --title "CREAR SAMBA" --inputbox "Nombre del compartido:" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$share_name" ]] && return

    local share_path
    share_path=$(whiptail --title "CREAR SAMBA" --inputbox "Ruta de la carpeta:" 8 60 "$WORK_DIR/shared_$share_name" 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$share_path" ]] && return
    mkdir -p "$share_path"

    local smb_conf="/etc/samba/smb.conf"

    if grep -q "^\[$share_name\]" "$smb_conf" 2>/dev/null; then
        whiptail --title "ERROR" --msgbox "Ya existe un compartido con ese nombre." 7 45
        return
    fi

    local modo
    modo=$(whiptail --title "MODO DE ACCESO" \
        --menu "\nSelecciona el modo de acceso:\n" 12 55 2 \
        "PUBLICO" "Acceso general (anonimo/guest)" \
        "RESTRINGIDO" "Acceso limitado (usuarios/grupos)" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $modo in
        PUBLICO)
            local perm
            perm=$(whiptail --title "PERMISOS PUBLICOS" \
                --menu "\nNivel de permisos:" 11 50 2 \
                "ro" "Solo lectura" \
                "rw" "Lectura y escritura" \
                3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            local read_only="yes"
            [[ "$perm" == "rw" ]] && read_only="no"

            chmod 777 "$share_path"
            cat >> "$smb_conf" <<EOF

[$share_name]
   comment = Compartido publico - $share_name
   path = $share_path
   browsable = yes
   guest ok = yes
   read only = $read_only
   create mask = 0666
   directory mask = 0777
   force user = nobody
EOF
            ;;
        RESTRINGIDO)
            local read_only="no"
            if whiptail --title "PERMISOS" --yesno "Solo lectura?" 7 30; then
                read_only="yes"
            fi

            local create_mask
            create_mask=$(whiptail --title "PERMISOS" --inputbox "Create mask:" 8 40 "0664" 3>&1 1>&2 2>&3)
            create_mask="${create_mask:-0664}"

            local dir_mask
            dir_mask=$(whiptail --title "PERMISOS" --inputbox "Directory mask:" 8 40 "0775" 3>&1 1>&2 2>&3)
            dir_mask="${dir_mask:-0775}"

            # Seleccionar usuarios
            local user_opt
            user_opt=$(whiptail --title "ASIGNAR USUARIOS" \
                --menu "\nSeleccionar usuarios para el compartido:\n" 13 55 3 \
                "EXISTENTES" "Usuarios temporales ya creados" \
                "NUEVO" "Crear usuario temporal nuevo" \
                "SISTEMA" "Especificar usuarios del sistema" \
                3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            local valid_users=""
            case $user_opt in
                EXISTENTES)
                    if [[ -s "$TEMP_USERS_FILE" ]]; then
                        local uitems=()
                        local ui=1
                        while IFS='|' read -r uname upriv; do
                            uitems+=("$uname" "Permisos: $upriv" "OFF")
                            ((ui++))
                        done < "$TEMP_USERS_FILE"
                        valid_users=$(whiptail --title "SELECCIONAR USUARIOS" \
                            --checklist "\nMarca los usuarios:\n" $H $W $MH \
                            "${uitems[@]}" 3>&1 1>&2 2>&3)
                        valid_users=$(echo "$valid_users" | tr -d '"')
                    else
                        whiptail --title "AVISO" --msgbox "No hay usuarios temporales.\nSe creara uno nuevo." 8 45
                        crear_usuario_temporal_tui
                        valid_users=$(tail -1 "$TEMP_USERS_FILE" | cut -d'|' -f1)
                    fi
                    ;;
                NUEVO)
                    crear_usuario_temporal_tui
                    valid_users=$(tail -1 "$TEMP_USERS_FILE" | cut -d'|' -f1)
                    ;;
                SISTEMA)
                    valid_users=$(whiptail --title "USUARIOS" --inputbox "Usuarios (separados por espacio):" 8 50 3>&1 1>&2 2>&3)
                    ;;
            esac
            [[ -z "$valid_users" ]] && return

            chmod 2775 "$share_path"
            cat >> "$smb_conf" <<EOF

[$share_name]
   comment = Compartido restringido - $share_name
   path = $share_path
   browsable = yes
   guest ok = no
   read only = $read_only
   valid users = $valid_users
   create mask = $create_mask
   directory mask = $dir_mask
   writable = yes
EOF
            ;;
    esac

    systemctl restart smbd 2>/dev/null
    systemctl restart nmbd 2>/dev/null
    whiptail --title "EXITO" --msgbox "Compartido '$share_name' creado.\nSamba reiniciado.\n\nRuta: $share_path" 10 55
    log_audit "COMPARTIDO CREADO (Samba): $share_name en $share_path (modo: $modo)"
}

crear_nfs() {
    verificar_dependencia "exportfs" "nfs-kernel-server"

    local share_path
    share_path=$(whiptail --title "CREAR NFS" --inputbox "Ruta de la carpeta a exportar:" 8 60 "$WORK_DIR/nfs_export" 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$share_path" ]] && return
    mkdir -p "$share_path"

    local allowed_net
    allowed_net=$(whiptail --title "CREAR NFS" --inputbox "Red permitida (ej: 192.168.1.0/24):\n(* para todas)" 9 55 "*" 3>&1 1>&2 2>&3)
    allowed_net="${allowed_net:-*}"

    local perm
    perm=$(whiptail --title "PERMISOS NFS" \
        --menu "\nNivel de permisos:" 11 45 2 \
        "ro" "Solo lectura" \
        "rw" "Lectura y escritura" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    local export_line="$share_path $allowed_net($perm,sync,no_subtree_check,no_root_squash)"

    if grep -qF "$share_path" /etc/exports 2>/dev/null; then
        whiptail --title "AVISO" --msgbox "Esta ruta ya esta exportada en /etc/exports." 7 50
        return
    fi

    echo "$export_line" >> /etc/exports
    exportfs -ra 2>/dev/null
    systemctl restart nfs-kernel-server 2>/dev/null
    chmod 2775 "$share_path"

    whiptail --title "EXITO" --msgbox "Exportacion NFS creada:\n\n$export_line" 9 65
    log_audit "COMPARTIDO CREADO (NFS): $export_line"
}

# Crear usuario temporal (TUI)
crear_usuario_temporal_tui() {
    local new_user
    new_user=$(whiptail --title "CREAR USUARIO TEMPORAL" --inputbox "Nombre de usuario:" 8 45 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$new_user" ]] && return 1

    local pass1="" pass2=""
    while true; do
        pass1=$(whiptail --title "CREAR USUARIO TEMPORAL" --passwordbox "Contrasena para $new_user:" 8 45 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return 1
        pass2=$(whiptail --title "CREAR USUARIO TEMPORAL" --passwordbox "Confirmar contrasena:" 8 45 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return 1

        if [[ "$pass1" == "$pass2" ]]; then
            break
        else
            whiptail --title "ERROR" --msgbox "Las contrasenas no coinciden.\nIntenta de nuevo." 8 40
        fi
    done

    local perms
    perms=$(whiptail --title "PERMISOS" \
        --menu "\nPermisos para $new_user:" 12 45 3 \
        "lectura" "Solo lectura" \
        "escritura" "Lectura y escritura" \
        "completo" "Control total" \
        3>&1 1>&2 2>&3)
    perms="${perms:-escritura}"

    # Crear usuario del sistema (sin shell)
    useradd -M -s /usr/sbin/nologin "$new_user" 2>/dev/null
    echo "$new_user:$pass1" | chpasswd
    (echo "$pass1"; echo "$pass1") | smbpasswd -a "$new_user" -s 2>/dev/null

    echo "$new_user|$perms" >> "$TEMP_USERS_FILE"
    whiptail --title "EXITO" --msgbox "Usuario temporal '$new_user' creado.\nPermisos: $perms" 8 45
    log_audit "USUARIO TEMPORAL CREADO: $new_user (permisos: $perms)"
}

# --- 6. Gestionar usuarios temporales ---
gestionar_usuarios_temp() {
    local opcion
    opcion=$(whiptail --title "USUARIOS TEMPORALES" \
        --menu "\nGestion de usuarios temporales:\n" 14 55 4 \
        "LISTAR" "Ver usuarios temporales" \
        "CREAR" "Crear nuevo usuario temporal" \
        "ASIGNAR" "Asignar usuario a compartido" \
        "ELIMINAR" "Eliminar usuario temporal" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $opcion in
        LISTAR)
            if [[ -s "$TEMP_USERS_FILE" ]]; then
                local info="USUARIO          | PERMISOS    | ESTADO\n"
                info+="─────────────────────────────────────────\n"
                while IFS='|' read -r uname upriv; do
                    local estado="activo"
                    id "$uname" &>/dev/null || estado="eliminado"
                    info+="$uname | $upriv | $estado\n"
                done < "$TEMP_USERS_FILE"
                mostrar_resultado "Usuarios Temporales" "$info"
            else
                whiptail --title "USUARIOS" --msgbox "No hay usuarios temporales registrados." 7 45
            fi
            ;;
        CREAR)
            crear_usuario_temporal_tui
            ;;
        ASIGNAR)
            local shares
            shares=$(grep -E "^\[" /etc/samba/smb.conf 2>/dev/null | grep -v "global\|printers\|homes" | tr -d '[]')
            if [[ -z "$shares" || ! -s "$TEMP_USERS_FILE" ]]; then
                whiptail --title "AVISO" --msgbox "No hay compartidos o usuarios disponibles." 7 48
                return
            fi

            # Seleccionar compartido
            local sitems=()
            while IFS= read -r s; do
                sitems+=("$s" "")
            done <<< "$shares"

            local share
            share=$(whiptail --title "ASIGNAR - Compartido" \
                --menu "\nSelecciona compartido:" $H $W $MH \
                "${sitems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$share" ]] && return

            # Seleccionar usuario
            local uitems=()
            while IFS='|' read -r uname upriv; do
                uitems+=("$uname" "$upriv" "OFF")
            done < "$TEMP_USERS_FILE"

            local usel
            usel=$(whiptail --title "ASIGNAR - Usuario" \
                --checklist "\nSelecciona usuarios para '$share':" $H $W $MH \
                "${uitems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$usel" ]] && return
            usel=$(echo "$usel" | tr -d '"')

            for u in $usel; do
                sed -i "/^\[$share\]/,/^\[/ s/valid users = .*/& $u/" /etc/samba/smb.conf 2>/dev/null
            done
            systemctl restart smbd 2>/dev/null
            whiptail --title "EXITO" --msgbox "Usuarios asignados al compartido '$share':\n$usel" 8 50
            log_audit "ASIGNACION: $usel -> compartido $share"
            ;;
        ELIMINAR)
            if [[ ! -s "$TEMP_USERS_FILE" ]]; then
                whiptail --title "AVISO" --msgbox "No hay usuarios temporales." 7 40
                return
            fi
            local ditems=()
            local di=1
            while IFS='|' read -r uname upriv; do
                ditems+=("$di" "$uname ($upriv)" "OFF")
                ((di++))
            done < "$TEMP_USERS_FILE"

            local dsel
            dsel=$(whiptail --title "ELIMINAR USUARIO" \
                --radiolist "\nSelecciona usuario a eliminar:" $H $W $MH \
                "${ditems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$dsel" ]] && return

            local uname=$(sed -n "${dsel}p" "$TEMP_USERS_FILE" | cut -d'|' -f1)
            if whiptail --title "CONFIRMAR" --yesno "Eliminar usuario '$uname'?" 7 35; then
                smbpasswd -x "$uname" 2>/dev/null
                userdel "$uname" 2>/dev/null
                sed -i "${dsel}d" "$TEMP_USERS_FILE"
                whiptail --title "EXITO" --msgbox "Usuario '$uname' eliminado." 7 40
                log_audit "USUARIO ELIMINADO: $uname"
            fi
            ;;
    esac
}

# =============================================================================
# C. DIAGNOSTICO Y PRUEBA DE CONECTIVIDAD
# =============================================================================

diagnostico() {
    local host
    host=$(whiptail --title "DIAGNOSTICO" --inputbox "Host a diagnosticar (IP o nombre):" 8 50 3>&1 1>&2 2>&3)
    [[ $? -ne 0 || -z "$host" ]] && return

    mostrar_progreso "Diagnostico" "Verificando puertos en $host..." 3

    local resultado="DIAGNOSTICO DE CONECTIVIDAD: $host\n"
    resultado+="════════════════════════════════════════\n\n"

    # Puertos
    resultado+="PUERTOS:\n"
    resultado+="────────\n"
    if check_port "$host" 445; then
        resultado+="  445 (SMB/CIFS):   ABIERTO\n"
    else
        resultado+="  445 (SMB/CIFS):   CERRADO/FILTRADO\n"
    fi
    if check_port "$host" 2049; then
        resultado+="  2049 (NFS):       ABIERTO\n"
    else
        resultado+="  2049 (NFS):       CERRADO/FILTRADO\n"
    fi
    if check_port "$host" 22; then
        resultado+="  22 (SSH/SSHFS):   ABIERTO\n"
    else
        resultado+="  22 (SSH/SSHFS):   CERRADO/FILTRADO\n"
    fi
    if check_port "$host" 139; then
        resultado+="  139 (NetBIOS):    ABIERTO\n"
    else
        resultado+="  139 (NetBIOS):    CERRADO/FILTRADO\n"
    fi

    # Ping
    resultado+="\nLATENCIA (ping):\n"
    resultado+="────────────────\n"
    local ping_out
    ping_out=$(ping -c 3 -W 2 "$host" 2>/dev/null | tail -1)
    resultado+="  $ping_out\n"

    # SMB resources
    if check_port "$host" 445; then
        resultado+="\nRECURSOS SMB:\n"
        resultado+="─────────────\n"
        local smb_out
        smb_out=$(smbclient -L "//$host" -N 2>/dev/null | grep -i "disk")
        resultado+="  ${smb_out:-No se pudieron listar}\n"
    fi

    # NFS exports
    if check_port "$host" 2049; then
        resultado+="\nEXPORTACIONES NFS:\n"
        resultado+="──────────────────\n"
        local nfs_out
        nfs_out=$(showmount -e "$host" 2>/dev/null | tail -n +2)
        resultado+="  ${nfs_out:-No se pudieron listar}\n"
    fi

    log_audit "DIAGNOSTICO realizado en $host"
    mostrar_resultado "Diagnostico: $host" "$resultado"
}

# =============================================================================
# D. OPCIONES AVANZADAS
# =============================================================================

# --- 8. Gestion de espacio y cuotas ---
gestion_cuotas() {
    local opcion
    opcion=$(whiptail --title "CUOTAS Y ESPACIO" \
        --menu "\nGestion de espacio:\n" 13 55 3 \
        "VER" "Ver uso de espacio por compartido" \
        "DEFINIR" "Definir cuota (espacio maximo)" \
        "LISTAR" "Ver cuotas configuradas" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $opcion in
        VER)
            local info="COMPARTIDO                  | USO\n"
            info+="─────────────────────────────────────────\n"
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_*; do
                [[ -d "$dir" ]] || continue
                local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
                info+="$(basename "$dir") | $size\n"
            done
            mount | grep "$MOUNT_DIR" 2>/dev/null | awk '{print $3}' | while read -r mp; do
                local uso=$(df -h "$mp" 2>/dev/null | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')
                info+="$(basename "$mp") (montado) | ${uso:-N/A}\n"
            done
            mostrar_resultado "Uso de Espacio" "$info"
            ;;
        DEFINIR)
            local dirs=()
            local i=1
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_*; do
                [[ -d "$dir" ]] || continue
                dirs+=("$i" "$(basename "$dir")")
                ((i++))
            done
            [[ ${#dirs[@]} -eq 0 ]] && { whiptail --title "AVISO" --msgbox "No hay compartidos." 7 35; return; }

            local sel
            sel=$(whiptail --title "DEFINIR CUOTA" \
                --menu "\nSelecciona compartido:" $H $W $MH \
                "${dirs[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            local idx=$(( (sel - 1) * 2 + 1 ))
            local target_name="${dirs[$idx]}"

            local max_space
            max_space=$(whiptail --title "CUOTA" --inputbox "Espacio maximo (ej: 500M, 2G):" 8 45 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$max_space" ]] && return

            local alert_pct
            alert_pct=$(whiptail --title "ALERTA" --inputbox "Alerta al alcanzar (%):" 8 40 "80" 3>&1 1>&2 2>&3)
            alert_pct="${alert_pct:-80}"

            local quota_file="$CONF_DIR/cuotas.conf"
            echo "$target_name|$max_space|$alert_pct" >> "$quota_file"
            whiptail --title "EXITO" --msgbox "Cuota definida:\n$target_name -> Max: $max_space | Alerta: ${alert_pct}%" 8 50
            log_audit "CUOTA: $target_name max=$max_space alerta=${alert_pct}%"
            ;;
        LISTAR)
            local quota_file="$CONF_DIR/cuotas.conf"
            if [[ -s "$quota_file" ]]; then
                local info="COMPARTIDO               | MAXIMO | ALERTA\n"
                info+="─────────────────────────────────────────────\n"
                while IFS='|' read -r name max alert; do
                    info+="$name | $max | ${alert}%\n"
                done < "$quota_file"
                mostrar_resultado "Cuotas Configuradas" "$info"
            else
                whiptail --title "CUOTAS" --msgbox "No hay cuotas definidas." 7 35
            fi
            ;;
    esac
}

# --- 9. Monitoreo e historial ---
monitoreo_historial() {
    local opcion
    opcion=$(whiptail --title "MONITOREO E HISTORIAL" \
        --menu "\nOpciones de monitoreo:\n" 14 55 4 \
        "SMB" "Conexiones Samba activas" \
        "NFS" "Conexiones NFS activas" \
        "LOG" "Ver log de auditoria completo" \
        "RECIENTE" "Ultimas 30 entradas del log" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $opcion in
        SMB)
            local info
            if command -v smbstatus &>/dev/null; then
                info=$(smbstatus 2>/dev/null)
                [[ -z "$info" ]] && info="No hay conexiones Samba activas."
            else
                info="smbstatus no disponible. Instala Samba."
            fi
            mostrar_resultado "Conexiones Samba" "$info"
            ;;
        NFS)
            local info=""
            info+="Clientes NFS (conexiones al puerto 2049):\n"
            info+="──────────────────────────────────────────\n"
            local nfs_clients
            nfs_clients=$(ss -tn sport = :2049 2>/dev/null)
            info+="${nfs_clients:-No hay conexiones activas}\n\n"
            info+="Exportaciones activas:\n"
            info+="──────────────────────\n"
            local exports
            exports=$(exportfs -v 2>/dev/null)
            info+="${exports:-Ninguna}"
            mostrar_resultado "Conexiones NFS" "$info"
            ;;
        LOG)
            if [[ -s "$AUDIT_LOG" ]]; then
                mostrar_resultado "Log de Auditoria" "$(cat "$AUDIT_LOG")"
            else
                whiptail --title "LOG" --msgbox "Log vacio." 7 30
            fi
            ;;
        RECIENTE)
            local info
            info=$(tail -30 "$AUDIT_LOG" 2>/dev/null)
            [[ -z "$info" ]] && info="No hay entradas recientes."
            mostrar_resultado "Ultimas 30 Entradas" "$info"
            ;;
    esac
}

# --- 10. Respaldos y restauracion ---
respaldos_restauracion() {
    local opcion
    opcion=$(whiptail --title "RESPALDOS Y RESTAURACION" \
        --menu "\nOpciones:\n" 14 55 4 \
        "TARGZ" "Crear respaldo .tar.gz" \
        "ZIP" "Crear respaldo .zip" \
        "RESTAURAR" "Restaurar desde respaldo" \
        "LISTAR" "Ver respaldos disponibles" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $opcion in
        TARGZ|ZIP)
            # Listar carpetas disponibles
            local ditems=()
            local i=1
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_* "$MOUNT_DIR"/*/; do
                [[ -d "$dir" ]] || continue
                local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
                ditems+=("$i" "$(basename "$dir") ($size)")
                ((i++))
            done
            [[ ${#ditems[@]} -eq 0 ]] && { whiptail --title "AVISO" --msgbox "No hay carpetas para respaldar." 7 40; return; }

            local sel
            sel=$(whiptail --title "RESPALDO" \
                --menu "\nSelecciona carpeta a respaldar:" $H $W $MH \
                "${ditems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            # Obtener la carpeta real
            local ci=1
            local src=""
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_* "$MOUNT_DIR"/*/; do
                [[ -d "$dir" ]] || continue
                if [[ $ci -eq $sel ]]; then
                    src="$dir"
                    break
                fi
                ((ci++))
            done
            [[ -z "$src" ]] && return

            local timestamp=$(date '+%Y%m%d_%H%M%S')
            local base_name="backup_$(basename "$src")_$timestamp"

            mostrar_progreso "Creando Respaldo" "Comprimiendo $(basename "$src")..." 4

            if [[ "$opcion" == "TARGZ" ]]; then
                tar -czf "$BACKUP_DIR/${base_name}.tar.gz" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null
                whiptail --title "EXITO" --msgbox "Respaldo creado:\n$BACKUP_DIR/${base_name}.tar.gz" 8 60
            else
                zip -r "$BACKUP_DIR/${base_name}.zip" "$src" &>/dev/null
                whiptail --title "EXITO" --msgbox "Respaldo creado:\n$BACKUP_DIR/${base_name}.zip" 8 60
            fi
            log_audit "RESPALDO: $(basename "$src") -> $BACKUP_DIR/$base_name"
            ;;
        RESTAURAR)
            local bitems=()
            local i=1
            for bk in "$BACKUP_DIR"/*; do
                [[ -f "$bk" ]] || continue
                local size=$(du -sh "$bk" 2>/dev/null | awk '{print $1}')
                bitems+=("$i" "$(basename "$bk") ($size)")
                ((i++))
            done
            [[ ${#bitems[@]} -eq 0 ]] && { whiptail --title "AVISO" --msgbox "No hay respaldos disponibles." 7 40; return; }

            local sel
            sel=$(whiptail --title "RESTAURAR" \
                --menu "\nSelecciona respaldo:" $H $W $MH \
                "${bitems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            local bi=1
            local bk_file=""
            for bk in "$BACKUP_DIR"/*; do
                [[ -f "$bk" ]] || continue
                if [[ $bi -eq $sel ]]; then
                    bk_file="$bk"
                    break
                fi
                ((bi++))
            done
            [[ -z "$bk_file" ]] && return

            local dest
            dest=$(whiptail --title "RESTAURAR" --inputbox "Directorio destino:" 8 55 "$WORK_DIR" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$dest" ]] && return
            mkdir -p "$dest"

            mostrar_progreso "Restaurando" "Extrayendo $(basename "$bk_file")..." 3

            if [[ "$bk_file" == *.tar.gz ]]; then
                tar -xzf "$bk_file" -C "$dest"
            elif [[ "$bk_file" == *.zip ]]; then
                unzip -o "$bk_file" -d "$dest" &>/dev/null
            fi
            whiptail --title "EXITO" --msgbox "Restaurado en: $dest" 7 50
            log_audit "RESTAURACION: $(basename "$bk_file") -> $dest"
            ;;
        LISTAR)
            local info="RESPALDOS DISPONIBLES:\n"
            info+="══════════════════════\n\n"
            local hay=0
            for bk in "$BACKUP_DIR"/*; do
                [[ -f "$bk" ]] || continue
                local size=$(du -sh "$bk" 2>/dev/null | awk '{print $1}')
                local fecha=$(stat -c '%y' "$bk" 2>/dev/null | cut -d'.' -f1)
                info+="$(basename "$bk")\n  Tamano: $size | Fecha: $fecha\n\n"
                hay=1
            done
            [[ $hay -eq 0 ]] && info+="No hay respaldos."
            mostrar_resultado "Respaldos" "$info"
            ;;
    esac
}

# --- 11. Mantenimiento ---
mantenimiento() {
    local opcion
    opcion=$(whiptail --title "MANTENIMIENTO" \
        --menu "\nOpciones de mantenimiento:\n" 14 55 4 \
        "FORZAR" "Forzar desmontaje (umount -l)" \
        "BLOQUEOS" "Liberar bloqueos (fuser -km)" \
        "RSYNC" "Sincronizacion con rsync" \
        "SERVICIOS" "Verificar estado de servicios" \
        3>&1 1>&2 2>&3)
    [[ $? -ne 0 ]] && return

    case $opcion in
        FORZAR)
            local montajes
            montajes=$(mount | grep "$MOUNT_DIR" 2>/dev/null)
            if [[ -z "$montajes" ]]; then
                whiptail --title "AVISO" --msgbox "No hay montajes activos." 7 35
                return
            fi

            local fitems=()
            local i=1
            while IFS= read -r line; do
                local mp=$(echo "$line" | awk '{print $3}')
                fitems+=("$mp" "" "OFF")
                ((i++))
            done <<< "$montajes"

            local mp_sel
            mp_sel=$(whiptail --title "FORZAR DESMONTAJE" \
                --radiolist "\nSelecciona punto de montaje:" $H $W $MH \
                "${fitems[@]}" 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$mp_sel" ]] && return

            if whiptail --title "CONFIRMAR" --yesno "Forzar desmontaje lazy de:\n$mp_sel?" 8 55; then
                umount -l "$mp_sel" 2>/dev/null
                if ! mountpoint -q "$mp_sel" 2>/dev/null; then
                    rmdir "$mp_sel" 2>/dev/null
                    whiptail --title "EXITO" --msgbox "Desmontado: $mp_sel" 7 50
                else
                    fuser -km "$mp_sel" 2>/dev/null
                    umount -l "$mp_sel" 2>/dev/null
                    whiptail --title "INFO" --msgbox "Se forzó la liberación con fuser." 7 45
                fi
                log_audit "MANTENIMIENTO: forzar desmontaje $mp_sel"
            fi
            ;;
        BLOQUEOS)
            local info=""
            local hay_bloqueo=0
            for mp in "$MOUNT_DIR"/*/; do
                [[ -d "$mp" ]] || continue
                local procs=$(fuser -m "$mp" 2>/dev/null)
                if [[ -n "$procs" ]]; then
                    info+="$mp -> PIDs: $procs\n"
                    hay_bloqueo=1
                fi
            done

            if [[ $hay_bloqueo -eq 0 ]]; then
                whiptail --title "BLOQUEOS" --msgbox "No hay procesos bloqueando montajes." 7 45
                return
            fi

            if whiptail --title "LIBERAR BLOQUEOS" --yesno "Procesos detectados:\n\n$info\n\nMatar procesos bloqueantes?" 14 55; then
                for mp in "$MOUNT_DIR"/*/; do
                    fuser -km "$mp" 2>/dev/null
                done
                whiptail --title "EXITO" --msgbox "Procesos liberados." 7 35
                log_audit "MANTENIMIENTO: bloqueos liberados"
            fi
            ;;
        RSYNC)
            verificar_dependencia "rsync" "rsync"

            local origen
            origen=$(whiptail --title "RSYNC" --inputbox "Origen (local o remoto user@host:/path):" 8 60 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$origen" ]] && return

            local destino
            destino=$(whiptail --title "RSYNC" --inputbox "Destino:" 8 60 3>&1 1>&2 2>&3)
            [[ $? -ne 0 || -z "$destino" ]] && return

            local modo_sync
            modo_sync=$(whiptail --title "RSYNC - MODO" \
                --menu "\nModo de sincronizacion:" 11 50 2 \
                "SYNC" "Solo sincronizar (no borrar extras)" \
                "MIRROR" "Mirror exacto (borrar extras en destino)" \
                3>&1 1>&2 2>&3)
            [[ $? -ne 0 ]] && return

            local rsync_opts="-avz --progress"
            [[ "$modo_sync" == "MIRROR" ]] && rsync_opts+=" --delete"

            # rsync necesita terminal interactiva para progreso
            clear
            echo "Ejecutando rsync..."
            echo "Origen:  $origen"
            echo "Destino: $destino"
            echo "Modo:    $modo_sync"
            echo ""
            rsync $rsync_opts "$origen" "$destino"
            echo ""
            echo "Sincronizacion completada. Presiona ENTER..."
            read -r
            log_audit "RSYNC: $origen -> $destino (modo: $modo_sync)"
            ;;
        SERVICIOS)
            local info="ESTADO DE SERVICIOS:\n"
            info+="════════════════════\n\n"
            for svc in smbd nmbd nfs-kernel-server sshd; do
                local estado=$(systemctl is-active "$svc" 2>/dev/null || echo "no instalado")
                local icono="✗"
                [[ "$estado" == "active" ]] && icono="✓"
                info+="  $icono  $svc: $estado\n"
            done
            mostrar_resultado "Servicios" "$info"
            ;;
    esac
}

# =============================================================================
# INICIO
# =============================================================================
menu_principal
