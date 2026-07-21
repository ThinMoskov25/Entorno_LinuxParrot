#!/bin/bash
# =============================================================================
# gestionar_compartidos.sh - Gestor de Unidades Compartidas (SMB/NFS/SSHFS)
# Autor: Moskov
# Uso: compartidos
# =============================================================================

G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

CONEXIONES_ROOT="/home/moskov/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios"
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

# Verificar root
if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

# =============================================================================
# UTILIDADES
# =============================================================================

get_ip() { hostname -I | awk '{print $1}'; }

log_audit() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AUDIT_LOG"
}

pausa() {
    echo ""
    read -rp "  Presiona ENTER para continuar..." _
}

check_port() {
    local host="$1" port="$2"
    timeout 3 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
}

verificar_dep() {
    local cmd="$1" pkg="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${Y}  [*] Instalando $pkg...${RST}"
        apt-get install -y "$pkg" &>/dev/null
    fi
}

banner() {
    clear
    echo -e "${C}"
    echo "  ========================================================"
    echo "       UNIDADES COMPARTIDAS - Gestor SMB/NFS/SSHFS"
    echo "  ========================================================"
    echo "   Montar · Crear · Diagnosticar · Respaldar · Gestionar"
    echo "  ========================================================"
    echo -e "${RST}"
}

# =============================================================================
# MENU PRINCIPAL
# =============================================================================

menu_principal() {
    banner
    local montajes=$(mount | grep -c "$MOUNT_DIR" 2>/dev/null || echo 0)
    echo -e "  ${DIM}IP Local: $(get_ip) | Montajes activos: $montajes${RST}"
    echo ""
    echo -e "  ${B}─── Cliente ───${RST}"
    echo -e "  ${G}1)${RST}  Escanear red (descubrir SMB/NFS)"
    echo -e "  ${G}2)${RST}  Conectar a unidad compartida"
    echo -e "  ${G}3)${RST}  Persistencia (automontaje fstab/systemd)"
    echo -e "  ${G}4)${RST}  Listar y desmontar unidades"
    echo ""
    echo -e "  ${B}─── Servidor ───${RST}"
    echo -e "  ${G}5)${RST}  Crear nueva unidad compartida"
    echo -e "  ${G}6)${RST}  Editar unidad compartida"
    echo -e "  ${G}7)${RST}  Gestionar usuarios temporales"
    echo ""
    echo -e "  ${B}─── Diagnostico ───${RST}"
    echo -e "  ${G}8)${RST}  Diagnostico y prueba de conectividad"
    echo ""
    echo -e "  ${B}─── Avanzado ───${RST}"
    echo -e "  ${G}9)${RST}  Cuotas y espacio"
    echo -e "  ${G}10)${RST} Monitoreo e historial"
    echo -e "  ${G}11)${RST} Respaldos y restauracion"
    echo -e "  ${G}12)${RST} Mantenimiento"
    echo ""
    echo -e "  ${G}0)${RST}  Salir"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1) escanear_red ;;
        2) conectar_unidad ;;
        3) persistencia_montaje ;;
        4) listar_desmontar ;;
        5) crear_compartido ;;
        6) editar_compartido ;;
        7) gestionar_usuarios ;;
        8) diagnostico ;;
        9) gestion_cuotas ;;
        10) monitoreo_historial ;;
        11) respaldos_restauracion ;;
        12) mantenimiento ;;
        0) echo -e "\n${G}  Hasta luego!${RST}\n"; exit 0 ;;
        *) echo -e "${R}  [!] Opcion no valida${RST}"; sleep 1 ;;
    esac
    menu_principal
}

# =============================================================================
# 1. ESCANEAR RED
# =============================================================================

escanear_red() {
    banner
    echo -e "${C}  Escaneo de red - Descubrimiento de recursos${RST}\n"
    verificar_dep "nmap" "nmap"
    verificar_dep "smbclient" "smbclient"

    local subnet
    subnet=$(ip route | grep -v default | grep "src $(get_ip)" | awk '{print $1}' | head -1)
    [[ -z "$subnet" ]] && subnet="$(get_ip | sed 's/\.[0-9]*$/.0\/24/')"

    echo -e "  ${DIM}Subred detectada: $subnet${RST}\n"
    echo -e "  ${G}1)${RST} Escanear SMB (puerto 445)"
    echo -e "  ${G}2)${RST} Escanear NFS (puerto 2049)"
    echo -e "  ${G}3)${RST} Escaneo completo (22, 445, 2049)"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo -e "\n${Y}  [*] Escaneando SMB en $subnet...${RST}\n"
            nmap -p 445 --open -oG - "$subnet" 2>/dev/null | grep "445/open" | awk '{print $2}' | while read -r host; do
                echo -e "  ${G}[+]${RST} Host: ${C}$host${RST}"
                smbclient -L "//$host" -N 2>/dev/null | grep -i "disk" | sed 's/^/      /'
            done
            log_audit "Escaneo SMB en $subnet"
            ;;
        2)
            verificar_dep "showmount" "nfs-common"
            echo -e "\n${Y}  [*] Escaneando NFS en $subnet...${RST}\n"
            nmap -p 2049 --open -oG - "$subnet" 2>/dev/null | grep "2049/open" | awk '{print $2}' | while read -r host; do
                echo -e "  ${G}[+]${RST} Host NFS: ${C}$host${RST}"
                showmount -e "$host" 2>/dev/null | tail -n +2 | sed 's/^/      /'
            done
            log_audit "Escaneo NFS en $subnet"
            ;;
        3)
            echo -e "\n${Y}  [*] Escaneo completo en $subnet...${RST}\n"
            nmap -p 22,445,2049 --open "$subnet" 2>/dev/null | grep -E "Nmap scan|open" | sed 's/^/  /'
            log_audit "Escaneo completo en $subnet"
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# 2. CONECTAR A UNIDAD COMPARTIDA
# =============================================================================

conectar_unidad() {
    banner
    echo -e "${C}  Conectar a Unidad Compartida${RST}\n"
    echo -e "  ${G}1)${RST} SMB/CIFS (puerto 445)"
    echo -e "  ${G}2)${RST} NFS (puerto 2049)"
    echo -e "  ${G}3)${RST} SSHFS (puerto 22)"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1) montar_smb ;;
        2) montar_nfs ;;
        3) montar_sshfs ;;
        0) return ;;
    esac
}

montar_smb() {
    banner
    echo -e "${C}  Montar recurso SMB/CIFS${RST}\n"
    verificar_dep "mount.cifs" "cifs-utils"

    read -rp "  Host (IP o nombre): " host
    echo -e "\n${Y}  [*] Verificando puerto 445...${RST}"
    if ! check_port "$host" 445; then
        echo -e "${R}  [!] Puerto 445 cerrado en $host. Abortado.${RST}"
        log_audit "FALLO: SMB puerto 445 cerrado en $host"
        pausa; return
    fi
    echo -e "${G}  [+] Puerto 445 abierto.${RST}\n"

    read -rp "  Recurso compartido: " share
    read -rp "  Usuario (vacio=guest): " user

    local mount_name="${host}_${share}"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    if [[ -n "$user" ]]; then
        read -rsp "  Password: " pass; echo ""
        local cred_file="$CRED_DIR/smb_${mount_name}.cred"
        echo -e "username=$user\npassword=$pass" > "$cred_file"
        chmod 600 "$cred_file"
        echo -e "${DIM}  Credenciales guardadas: $cred_file${RST}"
        mount -t cifs "//$host/$share" "$mount_point" -o "credentials=$cred_file,iocharset=utf8,vers=3.0" 2>/dev/null
    else
        mount -t cifs "//$host/$share" "$mount_point" -o "guest,iocharset=utf8,vers=3.0" 2>/dev/null
    fi

    if mountpoint -q "$mount_point" 2>/dev/null; then
        echo -e "\n${G}  [+] Montado: //$host/$share -> $mount_point${RST}"
        log_audit "MONTAJE SMB: //$host/$share en $mount_point"
    else
        echo -e "\n${R}  [!] Error al montar. Verifica credenciales.${RST}"
        rmdir "$mount_point" 2>/dev/null
    fi
    pausa
}

montar_nfs() {
    banner
    echo -e "${C}  Montar recurso NFS${RST}\n"
    verificar_dep "showmount" "nfs-common"

    read -rp "  Host (IP): " host
    echo -e "\n${Y}  [*] Verificando puerto 2049...${RST}"
    if ! check_port "$host" 2049; then
        echo -e "${R}  [!] Puerto 2049 cerrado. Abortado.${RST}"
        log_audit "FALLO: NFS puerto 2049 cerrado en $host"
        pausa; return
    fi
    echo -e "${G}  [+] Puerto 2049 abierto.${RST}\n"

    echo -e "  ${DIM}Exportaciones disponibles:${RST}"
    showmount -e "$host" 2>/dev/null | tail -n +2 | sed 's/^/    /'
    echo ""

    read -rp "  Ruta remota (ej: /export/data): " remote_path
    local mount_name="${host}_$(basename "$remote_path")"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    mount -t nfs "$host:$remote_path" "$mount_point" -o rw,sync 2>/dev/null

    if mountpoint -q "$mount_point" 2>/dev/null; then
        echo -e "\n${G}  [+] NFS montado: $host:$remote_path -> $mount_point${RST}"
        log_audit "MONTAJE NFS: $host:$remote_path en $mount_point"
    else
        echo -e "\n${R}  [!] Error al montar NFS.${RST}"
        rmdir "$mount_point" 2>/dev/null
    fi
    pausa
}

montar_sshfs() {
    banner
    echo -e "${C}  Montar recurso SSHFS${RST}\n"
    verificar_dep "sshfs" "sshfs"

    read -rp "  Host (IP): " host
    echo -e "\n${Y}  [*] Verificando puerto 22...${RST}"
    if ! check_port "$host" 22; then
        echo -e "${R}  [!] Puerto 22 cerrado. Abortado.${RST}"
        log_audit "FALLO: SSHFS puerto 22 cerrado en $host"
        pausa; return
    fi
    echo -e "${G}  [+] Puerto 22 abierto.${RST}\n"

    read -rp "  Usuario remoto: " user
    read -rp "  Ruta remota: " remote_path

    local mount_name="${host}_$(basename "$remote_path")"
    local mount_point="$MOUNT_DIR/$mount_name"
    mkdir -p "$mount_point"

    sshfs "$user@$host:$remote_path" "$mount_point" -o allow_other,reconnect,ServerAliveInterval=15

    if mountpoint -q "$mount_point" 2>/dev/null; then
        echo -e "\n${G}  [+] SSHFS montado: $user@$host:$remote_path -> $mount_point${RST}"
        log_audit "MONTAJE SSHFS: $user@$host:$remote_path en $mount_point"
    else
        echo -e "\n${R}  [!] Error al montar SSHFS.${RST}"
        rmdir "$mount_point" 2>/dev/null
    fi
    pausa
}

# =============================================================================
# 3. PERSISTENCIA (AUTOMONTAJE)
# =============================================================================

persistencia_montaje() {
    banner
    echo -e "${C}  Persistencia - Automontaje al arranque${RST}\n"

    local montajes
    montajes=$(mount | grep "$MOUNT_DIR" 2>/dev/null)
    if [[ -z "$montajes" ]]; then
        echo -e "${Y}  No hay montajes activos para hacer persistentes.${RST}"
        pausa; return
    fi

    local i=1
    declare -a entries
    while IFS= read -r line; do
        local src=$(echo "$line" | awk '{print $1}')
        local dst=$(echo "$line" | awk '{print $3}')
        local type=$(echo "$line" | awk '{print $5}')
        echo -e "  ${G}$i)${RST} [$type] $src -> $dst"
        entries[$i]="$line"
        ((i++))
    done <<< "$montajes"

    echo ""
    read -rp "  Selecciona montaje (0=cancelar): " sel
    [[ "$sel" == "0" || -z "$sel" ]] && return

    local selected="${entries[$sel]}"
    [[ -z "$selected" ]] && { echo -e "${R}  [!] Invalido.${RST}"; pausa; return; }

    local src=$(echo "$selected" | awk '{print $1}')
    local dst=$(echo "$selected" | awk '{print $3}')
    local type=$(echo "$selected" | awk '{print $5}')

    echo ""
    echo -e "  ${G}1)${RST} Agregar a /etc/fstab"
    echo -e "  ${G}2)${RST} Crear unidad systemd.mount"
    echo ""
    read -rp "  Metodo: " metodo

    case $metodo in
        1)
            local fstab_entry=""
            local cred_file="$CRED_DIR/smb_$(basename "$dst").cred"
            if [[ "$type" == "cifs" && -f "$cred_file" ]]; then
                fstab_entry="$src $dst cifs credentials=$cred_file,iocharset=utf8,vers=3.0,_netdev 0 0"
            elif [[ "$type" == "nfs" || "$type" == "nfs4" ]]; then
                fstab_entry="$src $dst nfs rw,sync,_netdev 0 0"
            elif [[ "$type" == "fuse.sshfs" ]]; then
                fstab_entry="$src $dst fuse.sshfs _netdev,allow_other,reconnect 0 0"
            fi
            if [[ -n "$fstab_entry" ]]; then
                if grep -qF "$dst" /etc/fstab; then
                    echo -e "${Y}  [!] Ya existe entrada en fstab.${RST}"
                else
                    echo "$fstab_entry" >> /etc/fstab
                    echo -e "${G}  [+] Agregado a /etc/fstab.${RST}"
                    echo -e "  ${DIM}$fstab_entry${RST}"
                    log_audit "PERSISTENCIA fstab: $fstab_entry"
                fi
            fi
            ;;
        2)
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
            systemctl enable "${unit_name}.mount" 2>/dev/null
            echo -e "${G}  [+] Unidad systemd creada: ${unit_name}.mount${RST}"
            log_audit "PERSISTENCIA systemd: ${unit_name}.mount"
            ;;
    esac
    pausa
}

# =============================================================================
# 4. LISTAR Y DESMONTAR
# =============================================================================

listar_desmontar() {
    banner
    echo -e "${C}  Unidades Compartidas y Montajes${RST}\n"

    # Recopilar compartidos Samba
    local smb_shares
    smb_shares=$(grep -E "^\[" /etc/samba/smb.conf 2>/dev/null | grep -v 'global\|printers\|homes\|print\$' | tr -d '[]')

    # Recopilar exportaciones NFS
    local nfs_exports
    nfs_exports=$(grep -v "^#\|^$" /etc/exports 2>/dev/null)

    # Montajes activos
    local montajes
    montajes=$(mount | grep "$MOUNT_DIR" 2>/dev/null)
    local -a mpoints=()

    # Mostrar Samba
    local -a samba_list=()
    local si=0
    if [[ -n "$smb_shares" ]]; then
        echo -e "  ${B}Compartidos Samba:${RST}"
        while IFS= read -r share; do
            local spath=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "path" | awk '{print $3}')
            local guest=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "guest ok" | awk '{print $4}')
            local modo="restringido"
            [[ "$guest" == "yes" ]] && modo="publico"
            samba_list[$si]="$share"
            echo -e "  ${G}S$((si+1)))${RST} $share ${DIM}($modo) -> $spath${RST}"
            ((si++))
        done <<< "$smb_shares"
        echo ""
    fi

    # Mostrar NFS
    local -a nfs_list=()
    local ni=0
    if [[ -n "$nfs_exports" ]]; then
        echo -e "  ${B}Exportaciones NFS:${RST}"
        while IFS= read -r line; do
            nfs_list[$ni]="$line"
            echo -e "  ${G}N$((ni+1)))${RST} $line"
            ((ni++))
        done <<< "$nfs_exports"
        echo ""
    fi

    # Mostrar montajes
    if [[ -n "$montajes" ]]; then
        echo -e "  ${B}Montajes activos:${RST}"
        local mi=1
        while IFS= read -r line; do
            local src=$(echo "$line" | awk '{print $1}')
            local dst=$(echo "$line" | awk '{print $3}')
            local type=$(echo "$line" | awk '{print $5}')
            local uso=$(df -h "$dst" 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')
            echo -e "  ${G}M$mi)${RST} [$type] $src -> $dst ${DIM}(${uso:-N/A})${RST}"
            mpoints[$mi]="$dst"
            ((mi++))
        done <<< "$montajes"
        echo ""
    else
        echo -e "  ${DIM}No hay montajes activos.${RST}\n"
    fi

    if [[ $si -eq 0 && $ni -eq 0 && ${#mpoints[@]} -eq 0 ]]; then
        echo -e "${Y}  No hay nada configurado.${RST}"
        pausa; return
    fi

    # Opciones
    echo -e "  ${B}Acciones:${RST}"
    echo -e "  ${G}es)${RST} Eliminar compartido Samba (quita share + carpeta + usuario)"
    echo -e "  ${G}en)${RST} Eliminar exportacion NFS (quita export + carpeta)"
    [[ ${#mpoints[@]} -gt 0 ]] && echo -e "  ${G}dm)${RST} Desmontar un montaje"
    echo -e "  ${G}all)${RST} Eliminar TODO (todos los shares + exports + montajes)"
    echo -e "  ${G}0)${RST}   Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        es)
            [[ $si -eq 0 ]] && { echo -e "${Y}  No hay compartidos Samba.${RST}"; pausa; return; }
            read -rp "  Numero de Samba a eliminar (S#): " num
            local idx=$((num - 1))
            local share="${samba_list[$idx]}"
            [[ -z "$share" ]] && { echo -e "${R}  [!] Invalido.${RST}"; pausa; return; }

            # Obtener ruta y usuarios
            local spath=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "path" | awk '{print $3}')
            local vusers=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "valid users" | sed 's/.*= //')

            # Eliminar share de smb.conf
            sed -i "/^\[$share\]/,/^$/d" /etc/samba/smb.conf 2>/dev/null
            echo -e "${G}  [+] Share '$share' eliminado de smb.conf${RST}"

            # Eliminar carpeta
            if [[ -d "$spath" ]]; then
                rm -rf "$spath"
                echo -e "${G}  [+] Carpeta eliminada: $spath${RST}"
            fi

            # Eliminar usuarios temporales asociados
            if [[ -n "$vusers" ]]; then
                for u in $vusers; do
                    smbpasswd -x "$u" 2>/dev/null
                    userdel "$u" 2>/dev/null
                    sed -i "/^$u|/d" "$TEMP_USERS_FILE" 2>/dev/null
                    echo -e "  ${DIM}Usuario '$u' eliminado${RST}"
                done
            fi

            systemctl restart smbd 2>/dev/null
            log_audit "ELIMINADO Samba: $share ($spath)"
            ;;
        en)
            [[ $ni -eq 0 ]] && { echo -e "${Y}  No hay exportaciones NFS.${RST}"; pausa; return; }
            read -rp "  Numero de NFS a eliminar (N#): " num
            local idx=$((num - 1))
            local export_line="${nfs_list[$idx]}"
            [[ -z "$export_line" ]] && { echo -e "${R}  [!] Invalido.${RST}"; pausa; return; }

            local nfs_path=$(echo "$export_line" | awk '{print $1}')

            # Eliminar de /etc/exports
            grep -vF "$nfs_path" /etc/exports > /tmp/exports_tmp && mv /tmp/exports_tmp /etc/exports
            exportfs -ra 2>/dev/null
            echo -e "${G}  [+] Exportacion eliminada de /etc/exports${RST}"

            # Eliminar carpeta
            if [[ -d "$nfs_path" ]]; then
                rm -rf "$nfs_path"
                echo -e "${G}  [+] Carpeta eliminada: $nfs_path${RST}"
            fi

            systemctl restart nfs-kernel-server 2>/dev/null
            log_audit "ELIMINADO NFS: $nfs_path"
            ;;
        dm)
            [[ ${#mpoints[@]} -eq 0 ]] && { echo -e "${Y}  No hay montajes.${RST}"; pausa; return; }
            read -rp "  Numero de montaje (M#): " num
            local mp="${mpoints[$num]}"
            if [[ -n "$mp" ]]; then
                umount "$mp" 2>/dev/null
                if ! mountpoint -q "$mp" 2>/dev/null; then
                    rmdir "$mp" 2>/dev/null
                    echo -e "${G}  [+] Desmontado: $mp${RST}"
                    log_audit "DESMONTAJE: $mp"
                else
                    echo -e "${R}  [!] No se pudo desmontar.${RST}"
                fi
            else
                echo -e "${R}  [!] Numero invalido.${RST}"
            fi
            ;;
        all)
            echo -e "\n${R}  [!] Esto eliminara TODOS los compartidos, exports y montajes.${RST}"
            read -rp "  Confirmar? (s/n): " confirm
            [[ "$confirm" != "s" ]] && { echo -e "  ${DIM}Cancelado.${RST}"; pausa; return; }

            # Eliminar todos los Samba
            for ((idx=0; idx<si; idx++)); do
                local share="${samba_list[$idx]}"
                local spath=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "path" | awk '{print $3}')
                local vusers=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "valid users" | sed 's/.*= //')
                sed -i "/^\[$share\]/,/^$/d" /etc/samba/smb.conf 2>/dev/null
                [[ -d "$spath" ]] && rm -rf "$spath"
                for u in $vusers; do
                    smbpasswd -x "$u" 2>/dev/null
                    userdel "$u" 2>/dev/null
                    sed -i "/^$u|/d" "$TEMP_USERS_FILE" 2>/dev/null
                done
                echo -e "  ${DIM}Samba '$share' eliminado${RST}"
            done

            # Eliminar todos los NFS
            for ((idx=0; idx<ni; idx++)); do
                local nfs_path=$(echo "${nfs_list[$idx]}" | awk '{print $1}')
                [[ -d "$nfs_path" ]] && rm -rf "$nfs_path"
                echo -e "  ${DIM}NFS '$nfs_path' eliminado${RST}"
            done
            echo "" > /etc/exports 2>/dev/null
            exportfs -ra 2>/dev/null

            # Desmontar todos los montajes
            for mp in "${mpoints[@]}"; do
                [[ -z "$mp" ]] && continue
                umount "$mp" 2>/dev/null && rmdir "$mp" 2>/dev/null
                echo -e "  ${DIM}Desmontado: $mp${RST}"
            done

            systemctl restart smbd 2>/dev/null
            systemctl restart nfs-kernel-server 2>/dev/null
            echo -e "\n${G}  [+] Todo eliminado y servicios reiniciados.${RST}"
            log_audit "ELIMINACION TOTAL: $si Samba, $ni NFS, ${#mpoints[@]} montajes"
            ;;
        0) return ;;
        *) echo -e "${R}  [!] Opcion no valida.${RST}" ;;
    esac
    pausa
}

# =============================================================================
# 5. CREAR COMPARTIDO
# =============================================================================

crear_compartido() {
    banner
    echo -e "${C}  Crear nueva unidad compartida${RST}\n"
    echo -e "  ${G}1)${RST} Samba (SMB)"
    echo -e "  ${G}2)${RST} NFS"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1) crear_samba ;;
        2) crear_nfs ;;
        0) return ;;
    esac
}

crear_samba() {
    banner
    echo -e "${C}  Crear compartido Samba${RST}\n"
    verificar_dep "smbd" "samba"

    read -rp "  Nombre del compartido: " share_name
    read -rp "  Ruta [$WORK_DIR/shared_$share_name]: " share_path
    share_path="${share_path:-$WORK_DIR/shared_$share_name}"
    mkdir -p "$share_path"

    local smb_conf="/etc/samba/smb.conf"
    if grep -q "^\[$share_name\]" "$smb_conf" 2>/dev/null; then
        echo -e "${R}  [!] Ya existe un compartido con ese nombre.${RST}"
        pausa; return
    fi

    echo ""
    echo -e "  ${B}Modo de acceso:${RST}"
    echo -e "  ${G}1)${RST} Publico (anonimo)"
    echo -e "  ${G}2)${RST} Restringido (usuarios)"
    echo -e "  ${G}3)${RST} Predeterminado (cualquier usuario autenticado, lectura/escritura)"
    echo ""
    read -rp "  Modo: " modo

    case $modo in
        1)
            echo -e "  ${G}a)${RST} Solo lectura"
            echo -e "  ${G}b)${RST} Lectura/Escritura"
            read -rp "  Permiso: " perm
            local read_only="yes"
            [[ "$perm" == "b" ]] && read_only="no"
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
            echo -e "\n${G}  [+] Compartido publico '$share_name' creado.${RST}"
            ;;
        3)
            chmod 2770 "$share_path"
            chown root:sambashare "$share_path" 2>/dev/null || chown root:users "$share_path" 2>/dev/null
            cat >> "$smb_conf" <<EOF

[$share_name]
   comment = Compartido predeterminado - $share_name
   path = $share_path
   browsable = yes
   guest ok = no
   read only = no
   writable = yes
   valid users = @sambashare, @users
   create mask = 0660
   directory mask = 0770
   force create mode = 0660
   force directory mode = 0770
   inherit permissions = yes
EOF
            echo -e "\n${G}  [+] Compartido '$share_name' creado (predeterminado).${RST}"
            echo -e "  ${DIM}Acceso: cualquier usuario autenticado del grupo sambashare/users${RST}"
            echo -e "  ${DIM}Permisos: lectura/escritura con proteccion de grupo${RST}"
            ;;
        2)
            read -rp "  Solo lectura? (s/n) [n]: " ro
            local read_only="no"
            [[ "$ro" == "s" ]] && read_only="yes"
            read -rp "  Create mask [0664]: " create_mask
            create_mask="${create_mask:-0664}"
            read -rp "  Directory mask [0775]: " dir_mask
            dir_mask="${dir_mask:-0775}"

            echo ""
            echo -e "  ${B}Asignar usuarios:${RST}"
            echo -e "  ${G}1)${RST} Temporales existentes"
            echo -e "  ${G}2)${RST} Crear usuario temporal"
            echo -e "  ${G}3)${RST} Escribir manualmente"
            read -rp "  Opcion: " uopt

            local valid_users=""
            case $uopt in
                1)
                    if [[ -s "$TEMP_USERS_FILE" ]]; then
                        echo ""
                        cat -n "$TEMP_USERS_FILE" | sed 's/|/ | /'
                        echo ""
                        read -rp "  Nombres separados por espacio: " valid_users
                    else
                        echo -e "${Y}  No hay temporales. Creando...${RST}"
                        crear_usuario_temporal
                        valid_users=$(tail -1 "$TEMP_USERS_FILE" | cut -d'|' -f1)
                    fi
                    ;;
                2)
                    crear_usuario_temporal
                    valid_users=$(tail -1 "$TEMP_USERS_FILE" | cut -d'|' -f1)
                    ;;
                3) read -rp "  Usuarios (separados por espacio): " valid_users ;;
            esac
            [[ -z "$valid_users" ]] && { echo -e "${R}  [!] Sin usuarios.${RST}"; pausa; return; }

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
            echo -e "\n${G}  [+] Compartido '$share_name' creado.${RST}"
            echo -e "  ${DIM}Usuarios: $valid_users${RST}"
            ;;
    esac

    systemctl restart smbd 2>/dev/null
    systemctl restart nmbd 2>/dev/null
    echo -e "${G}  [+] Samba reiniciado.${RST}"
    log_audit "COMPARTIDO CREADO (Samba): $share_name en $share_path"
    pausa
}

crear_nfs() {
    banner
    echo -e "${C}  Crear compartido NFS${RST}\n"
    verificar_dep "exportfs" "nfs-kernel-server"

    read -rp "  Ruta a exportar [$WORK_DIR/nfs_export]: " share_path
    share_path="${share_path:-$WORK_DIR/nfs_export}"
    mkdir -p "$share_path"

    read -rp "  Red permitida (ej: 192.168.1.0/24) [*]: " allowed_net
    allowed_net="${allowed_net:-*}"

    echo -e "  ${G}1)${RST} Solo lectura (ro)"
    echo -e "  ${G}2)${RST} Lectura/Escritura (rw)"
    read -rp "  Permiso: " perm
    local nfs_perm="ro"
    [[ "$perm" == "2" ]] && nfs_perm="rw"

    local export_line="$share_path $allowed_net($nfs_perm,sync,no_subtree_check,no_root_squash)"

    if grep -qF "$share_path" /etc/exports 2>/dev/null; then
        echo -e "${Y}  [!] Ya exportada en /etc/exports.${RST}"
    else
        echo "$export_line" >> /etc/exports
        exportfs -ra 2>/dev/null
        systemctl restart nfs-kernel-server 2>/dev/null
        chmod 2775 "$share_path"
        echo -e "\n${G}  [+] Exportacion NFS creada:${RST}"
        echo -e "  ${DIM}$export_line${RST}"
        log_audit "COMPARTIDO CREADO (NFS): $export_line"
    fi
    pausa
}

# =============================================================================
# =============================================================================
# 6. EDITAR UNIDAD COMPARTIDA
# =============================================================================

editar_compartido() {
    banner
    echo -e "${C}  Editar Unidad Compartida${RST}\n"

    # Listar compartidos Samba
    local smb_shares
    smb_shares=$(grep -E "^\[" /etc/samba/smb.conf 2>/dev/null | grep -v 'global\|printers\|homes\|print\$' | tr -d '[]')

    if [[ -z "$smb_shares" ]]; then
        echo -e "${Y}  No hay compartidos para editar.${RST}"
        pausa; return
    fi

    local -a share_list=()
    local i=1
    echo -e "  ${B}Compartidos disponibles:${RST}\n"
    while IFS= read -r share; do
        local spath=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "path" | awk '{print $3}')
        local guest=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "guest ok" | awk '{print $4}')
        local ro=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "read only" | awk '{print $4}')
        local vusers=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "valid users" | sed 's/.*= //')
        local cmask=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "create mask" | awk '{print $4}')
        local dmask=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf 2>/dev/null | grep "directory mask" | awk '{print $4}')

        local modo="restringido"
        [[ "$guest" == "yes" ]] && modo="publico"

        share_list[$i]="$share"
        echo -e "  ${G}$i)${RST} ${B}$share${RST} ($modo)"
        echo -e "     ${DIM}Ruta: $spath${RST}"
        echo -e "     ${DIM}Lectura: $ro | Usuarios: ${vusers:-todos} | Mask: ${cmask:-N/A}/${dmask:-N/A}${RST}"
        echo ""
        ((i++))
    done <<< "$smb_shares"

    read -rp "  Selecciona compartido a editar (0=volver): " sel
    [[ "$sel" == "0" || -z "$sel" ]] && return

    local share="${share_list[$sel]}"
    [[ -z "$share" ]] && { echo -e "${R}  [!] Invalido.${RST}"; pausa; return; }

    banner
    echo -e "${C}  Editando: ${B}$share${RST}\n"
    echo -e "  ${G}1)${RST} Cambiar permisos (read only)"
    echo -e "  ${G}2)${RST} Cambiar create mask / directory mask"
    echo -e "  ${G}3)${RST} Cambiar modo (publico <-> restringido)"
    echo -e "  ${G}4)${RST} Agregar usuario con acceso"
    echo -e "  ${G}5)${RST} Quitar usuario de acceso"
    echo -e "  ${G}6)${RST} Cambiar ruta del compartido"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo ""
            echo -e "  ${G}a)${RST} Solo lectura"
            echo -e "  ${G}b)${RST} Lectura/Escritura"
            read -rp "  Permiso: " perm
            if [[ "$perm" == "a" ]]; then
                sed -i "/^\[$share\]/,/^\[/ s/read only = .*/read only = yes/" /etc/samba/smb.conf
                echo -e "${G}  [+] '$share' -> Solo lectura${RST}"
            elif [[ "$perm" == "b" ]]; then
                sed -i "/^\[$share\]/,/^\[/ s/read only = .*/read only = no/" /etc/samba/smb.conf
                echo -e "${G}  [+] '$share' -> Lectura/Escritura${RST}"
            fi
            ;;
        2)
            echo ""
            read -rp "  Nuevo create mask [0664]: " cmask
            cmask="${cmask:-0664}"
            read -rp "  Nuevo directory mask [0775]: " dmask
            dmask="${dmask:-0775}"
            sed -i "/^\[$share\]/,/^\[/ s/create mask = .*/create mask = $cmask/" /etc/samba/smb.conf
            sed -i "/^\[$share\]/,/^\[/ s/directory mask = .*/directory mask = $dmask/" /etc/samba/smb.conf
            # Aplicar a la carpeta
            local spath=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf | grep "path" | awk '{print $3}')
            chmod "$dmask" "$spath" 2>/dev/null
            echo -e "${G}  [+] Masks actualizados: create=$cmask dir=$dmask${RST}"
            ;;
        3)
            local guest=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf | grep "guest ok" | awk '{print $4}')
            if [[ "$guest" == "yes" ]]; then
                # Pasar a restringido
                sed -i "/^\[$share\]/,/^\[/ s/guest ok = yes/guest ok = no/" /etc/samba/smb.conf
                echo ""
                read -rp "  Usuarios permitidos (espacio): " users
                # Agregar valid users si no existe
                if grep -A20 "^\[$share\]" /etc/samba/smb.conf | grep -q "valid users"; then
                    sed -i "/^\[$share\]/,/^\[/ s/valid users = .*/valid users = $users/" /etc/samba/smb.conf
                else
                    sed -i "/^\[$share\]/a\\   valid users = $users" /etc/samba/smb.conf
                fi
                echo -e "${G}  [+] '$share' -> Restringido (usuarios: $users)${RST}"
            else
                # Pasar a publico
                sed -i "/^\[$share\]/,/^\[/ s/guest ok = no/guest ok = yes/" /etc/samba/smb.conf
                sed -i "/^\[$share\]/,/^\[/ {/valid users/d}" /etc/samba/smb.conf
                echo -e "${G}  [+] '$share' -> Publico (acceso anonimo)${RST}"
            fi
            ;;
        4)
            echo ""
            echo -e "  ${G}1)${RST} Agregar usuario existente del sistema"
            echo -e "  ${G}2)${RST} Crear usuario temporal nuevo"
            read -rp "  Opcion: " uopt
            local new_user=""
            case $uopt in
                1) read -rp "  Nombre de usuario: " new_user ;;
                2)
                    crear_usuario_temporal
                    new_user=$(tail -1 "$TEMP_USERS_FILE" | cut -d'|' -f1)
                    ;;
            esac
            if [[ -n "$new_user" ]]; then
                if grep -A20 "^\[$share\]" /etc/samba/smb.conf | grep -q "valid users"; then
                    sed -i "/^\[$share\]/,/^\[/ s/valid users = .*/& $new_user/" /etc/samba/smb.conf
                else
                    sed -i "/^\[$share\]/a\\   valid users = $new_user" /etc/samba/smb.conf
                fi
                echo -e "${G}  [+] '$new_user' agregado a '$share'${RST}"
            fi
            ;;
        5)
            local vusers=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf | grep "valid users" | sed 's/.*= //')
            if [[ -z "$vusers" ]]; then
                echo -e "${Y}  Este compartido es publico, no tiene usuarios asignados.${RST}"
            else
                echo -e "\n  Usuarios actuales: ${C}$vusers${RST}\n"
                read -rp "  Usuario a quitar: " del_user
                local new_list=$(echo "$vusers" | sed "s/\b$del_user\b//g" | xargs)
                sed -i "/^\[$share\]/,/^\[/ s/valid users = .*/valid users = $new_list/" /etc/samba/smb.conf
                echo -e "${G}  [+] '$del_user' quitado de '$share'${RST}"
                echo -e "  ${DIM}Usuarios restantes: $new_list${RST}"
            fi
            ;;
        6)
            local old_path=$(sed -n "/^\[$share\]/,/^\[/p" /etc/samba/smb.conf | grep "path" | awk '{print $3}')
            echo -e "\n  Ruta actual: ${C}$old_path${RST}\n"
            read -rp "  Nueva ruta: " new_path
            if [[ -n "$new_path" ]]; then
                mkdir -p "$new_path"
                # Mover contenido si la ruta vieja existe
                if [[ -d "$old_path" ]]; then
                    read -rp "  Mover contenido de la ruta anterior? (s/n): " mover
                    [[ "$mover" == "s" ]] && mv "$old_path"/* "$new_path/" 2>/dev/null && rmdir "$old_path" 2>/dev/null
                fi
                sed -i "/^\[$share\]/,/^\[/ s|path = .*|path = $new_path|" /etc/samba/smb.conf
                echo -e "${G}  [+] Ruta cambiada: $new_path${RST}"
            fi
            ;;
        0) return ;;
    esac

    # Reiniciar Samba
    systemctl restart smbd 2>/dev/null
    echo -e "${G}  [+] Samba reiniciado.${RST}"
    log_audit "EDITADO compartido '$share' (opcion $opt)"
    pausa
}

# =============================================================================
# 7. GESTIONAR USUARIOS TEMPORALES
# =============================================================================

crear_usuario_temporal() {
    echo -e "\n${C}  --- Crear Usuario Temporal ---${RST}"
    read -rp "  Nombre de usuario: " new_user

    local pass1="" pass2=""
    while true; do
        read -rsp "  Contrasena: " pass1; echo ""
        read -rsp "  Confirmar: " pass2; echo ""
        [[ "$pass1" == "$pass2" ]] && break
        echo -e "${R}  [!] No coinciden. Intenta de nuevo.${RST}"
    done

    read -rp "  Permisos (lectura/escritura/completo) [escritura]: " perms
    perms="${perms:-escritura}"

    useradd -M -s /usr/sbin/nologin "$new_user" 2>/dev/null
    echo "$new_user:$pass1" | chpasswd 2>/dev/null
    (echo "$pass1"; echo "$pass1") | smbpasswd -a "$new_user" -s 2>/dev/null

    echo "$new_user|$perms" >> "$TEMP_USERS_FILE"
    echo -e "${G}  [+] Usuario '$new_user' creado (permisos: $perms).${RST}"
    log_audit "USUARIO TEMPORAL CREADO: $new_user ($perms)"
}

gestionar_usuarios() {
    banner
    echo -e "${C}  Gestion de Usuarios Temporales${RST}\n"
    echo -e "  ${G}1)${RST} Listar usuarios"
    echo -e "  ${G}2)${RST} Crear nuevo"
    echo -e "  ${G}3)${RST} Asignar a compartido"
    echo -e "  ${G}4)${RST} Eliminar usuario"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo ""
            if [[ -s "$TEMP_USERS_FILE" ]]; then
                local i=1
                while IFS='|' read -r uname upriv; do
                    local estado="activo"
                    id "$uname" &>/dev/null || estado="eliminado"
                    echo -e "  ${G}$i)${RST} $uname | Permisos: $upriv | Estado: $estado"
                    ((i++))
                done < "$TEMP_USERS_FILE"
            else
                echo -e "  ${Y}No hay usuarios temporales.${RST}"
            fi
            ;;
        2) crear_usuario_temporal ;;
        3)
            echo ""
            local shares
            shares=$(grep -E "^\[" /etc/samba/smb.conf 2>/dev/null | grep -v "global\|printers\|homes" | tr -d '[]')
            if [[ -z "$shares" || ! -s "$TEMP_USERS_FILE" ]]; then
                echo -e "${Y}  No hay compartidos o usuarios.${RST}"
            else
                echo -e "  ${B}Compartidos:${RST}"
                echo "$shares" | nl -ba | sed 's/^/  /'
                echo ""
                read -rp "  Nombre del compartido: " share
                echo ""
                echo -e "  ${B}Usuarios temporales:${RST}"
                cat -n "$TEMP_USERS_FILE" | sed 's/|/ | /' | sed 's/^/  /'
                echo ""
                read -rp "  Usuarios a asignar (espacio): " usel
                for u in $usel; do
                    sed -i "/^\[$share\]/,/^\[/ s/valid users = .*/& $u/" /etc/samba/smb.conf 2>/dev/null
                done
                systemctl restart smbd 2>/dev/null
                echo -e "${G}  [+] Usuarios asignados a '$share'.${RST}"
                log_audit "ASIGNACION: $usel -> $share"
            fi
            ;;
        4)
            echo ""
            cat -n "$TEMP_USERS_FILE" 2>/dev/null | sed 's/|/ | /' | sed 's/^/  /'
            echo ""
            read -rp "  Numero a eliminar: " num
            local uname=$(sed -n "${num}p" "$TEMP_USERS_FILE" | cut -d'|' -f1)
            if [[ -n "$uname" ]]; then
                smbpasswd -x "$uname" 2>/dev/null
                userdel "$uname" 2>/dev/null
                sed -i "${num}d" "$TEMP_USERS_FILE"
                echo -e "${G}  [+] '$uname' eliminado.${RST}"
                log_audit "USUARIO ELIMINADO: $uname"
            fi
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# 7. DIAGNOSTICO
# =============================================================================

diagnostico() {
    banner
    echo -e "${C}  Diagnostico de Conectividad${RST}\n"
    read -rp "  Host a diagnosticar: " host

    echo -e "\n  ${B}Verificando puertos:${RST}\n"

    echo -ne "  Puerto 445 (SMB):    "
    check_port "$host" 445 && echo -e "${G}ABIERTO${RST}" || echo -e "${R}CERRADO${RST}"

    echo -ne "  Puerto 2049 (NFS):   "
    check_port "$host" 2049 && echo -e "${G}ABIERTO${RST}" || echo -e "${R}CERRADO${RST}"

    echo -ne "  Puerto 22 (SSHFS):   "
    check_port "$host" 22 && echo -e "${G}ABIERTO${RST}" || echo -e "${R}CERRADO${RST}"

    echo -ne "  Puerto 139 (NetBIOS):"
    check_port "$host" 139 && echo -e "${G}ABIERTO${RST}" || echo -e "${R}CERRADO${RST}"

    echo -e "\n  ${B}Latencia:${RST}"
    ping -c 3 -W 2 "$host" 2>/dev/null | tail -1 | sed 's/^/  /'

    if check_port "$host" 445; then
        echo -e "\n  ${B}Recursos SMB:${RST}"
        smbclient -L "//$host" -N 2>/dev/null | grep -i "disk" | sed 's/^/  /'
    fi

    if check_port "$host" 2049; then
        echo -e "\n  ${B}Exportaciones NFS:${RST}"
        showmount -e "$host" 2>/dev/null | tail -n +2 | sed 's/^/  /'
    fi

    log_audit "DIAGNOSTICO en $host"
    pausa
}

# =============================================================================
# 8. CUOTAS Y ESPACIO
# =============================================================================

gestion_cuotas() {
    banner
    echo -e "${C}  Gestion de Espacio y Cuotas${RST}\n"
    echo -e "  ${G}1)${RST} Ver uso por compartido"
    echo -e "  ${G}2)${RST} Definir cuota"
    echo -e "  ${G}3)${RST} Ver cuotas configuradas"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo ""
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_*; do
                [[ -d "$dir" ]] || continue
                local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
                echo -e "  $(basename "$dir"): ${C}$size${RST}"
            done
            mount | grep "$MOUNT_DIR" 2>/dev/null | awk '{print $3}' | while read -r mp; do
                local uso=$(df -h "$mp" 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')
                echo -e "  $(basename "$mp") (montado): ${C}${uso:-N/A}${RST}"
            done
            ;;
        2)
            echo ""
            local i=1
            declare -a dirs
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_*; do
                [[ -d "$dir" ]] || continue
                echo -e "  ${G}$i)${RST} $(basename "$dir")"
                dirs[$i]="$dir"
                ((i++))
            done
            [[ $i -eq 1 ]] && { echo -e "  ${Y}No hay compartidos.${RST}"; pausa; return; }
            echo ""
            read -rp "  Selecciona: " sel
            local target="${dirs[$sel]}"
            [[ -z "$target" ]] && { pausa; return; }

            read -rp "  Espacio maximo (ej: 500M, 2G): " max_space
            read -rp "  Alerta al (%) [80]: " alert_pct
            alert_pct="${alert_pct:-80}"

            echo "$(basename "$target")|$max_space|$alert_pct" >> "$CONF_DIR/cuotas.conf"
            echo -e "\n${G}  [+] Cuota: $(basename "$target") -> Max: $max_space | Alerta: ${alert_pct}%${RST}"
            log_audit "CUOTA: $(basename "$target") max=$max_space alerta=${alert_pct}%"
            ;;
        3)
            echo ""
            local quota_file="$CONF_DIR/cuotas.conf"
            if [[ -s "$quota_file" ]]; then
                printf "  %-25s %-10s %-10s\n" "COMPARTIDO" "MAXIMO" "ALERTA"
                echo "  ──────────────────────────────────────────"
                while IFS='|' read -r name max alert; do
                    printf "  %-25s %-10s %-10s\n" "$name" "$max" "${alert}%"
                done < "$quota_file"
            else
                echo -e "  ${Y}No hay cuotas definidas.${RST}"
            fi
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# 9. MONITOREO E HISTORIAL
# =============================================================================

monitoreo_historial() {
    banner
    echo -e "${C}  Monitoreo e Historial${RST}\n"
    echo -e "  ${G}1)${RST} Conexiones Samba activas"
    echo -e "  ${G}2)${RST} Conexiones NFS activas"
    echo -e "  ${G}3)${RST} Log de auditoria completo"
    echo -e "  ${G}4)${RST} Ultimas 30 entradas"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo ""
            if command -v smbstatus &>/dev/null; then
                smbstatus 2>/dev/null | sed 's/^/  /'
            else
                echo -e "  ${Y}smbstatus no disponible.${RST}"
            fi
            ;;
        2)
            echo -e "\n  ${B}Clientes NFS:${RST}"
            ss -tn sport = :2049 2>/dev/null | sed 's/^/  /'
            echo -e "\n  ${B}Exportaciones activas:${RST}"
            exportfs -v 2>/dev/null | sed 's/^/  /'
            ;;
        3)
            echo ""
            if [[ -s "$AUDIT_LOG" ]]; then
                cat "$AUDIT_LOG" | sed 's/^/  /'
            else
                echo -e "  ${Y}Log vacio.${RST}"
            fi
            ;;
        4)
            echo ""
            tail -30 "$AUDIT_LOG" 2>/dev/null | sed 's/^/  /'
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# 10. RESPALDOS Y RESTAURACION
# =============================================================================

respaldos_restauracion() {
    banner
    echo -e "${C}  Respaldos y Restauracion${RST}\n"
    echo -e "  ${G}1)${RST} Crear respaldo .tar.gz"
    echo -e "  ${G}2)${RST} Crear respaldo .zip"
    echo -e "  ${G}3)${RST} Restaurar"
    echo -e "  ${G}4)${RST} Listar respaldos"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1|2)
            echo ""
            local i=1
            declare -a dirs
            for dir in "$WORK_DIR"/shared_* "$WORK_DIR"/nfs_* "$MOUNT_DIR"/*/; do
                [[ -d "$dir" ]] || continue
                local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
                echo -e "  ${G}$i)${RST} $(basename "$dir") ($size)"
                dirs[$i]="$dir"
                ((i++))
            done
            [[ $i -eq 1 ]] && { echo -e "  ${Y}No hay carpetas.${RST}"; pausa; return; }
            echo ""
            read -rp "  Selecciona: " sel
            local src="${dirs[$sel]}"
            [[ -z "$src" ]] && { pausa; return; }

            local timestamp=$(date '+%Y%m%d_%H%M%S')
            local base_name="backup_$(basename "$src")_$timestamp"

            echo -e "\n${Y}  [*] Creando respaldo...${RST}"
            if [[ "$opt" == "1" ]]; then
                tar -czf "$BACKUP_DIR/${base_name}.tar.gz" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null
                echo -e "${G}  [+] $BACKUP_DIR/${base_name}.tar.gz${RST}"
            else
                zip -r "$BACKUP_DIR/${base_name}.zip" "$src" &>/dev/null
                echo -e "${G}  [+] $BACKUP_DIR/${base_name}.zip${RST}"
            fi
            log_audit "RESPALDO: $(basename "$src")"
            ;;
        3)
            echo ""
            local i=1
            declare -a backups
            for bk in "$BACKUP_DIR"/*; do
                [[ -f "$bk" ]] || continue
                local size=$(du -sh "$bk" 2>/dev/null | awk '{print $1}')
                echo -e "  ${G}$i)${RST} $(basename "$bk") ($size)"
                backups[$i]="$bk"
                ((i++))
            done
            [[ $i -eq 1 ]] && { echo -e "  ${Y}No hay respaldos.${RST}"; pausa; return; }
            echo ""
            read -rp "  Selecciona: " sel
            local bk_file="${backups[$sel]}"
            [[ -z "$bk_file" ]] && { pausa; return; }
            read -rp "  Destino [$WORK_DIR]: " dest
            dest="${dest:-$WORK_DIR}"
            mkdir -p "$dest"

            echo -e "\n${Y}  [*] Restaurando...${RST}"
            if [[ "$bk_file" == *.tar.gz ]]; then
                tar -xzf "$bk_file" -C "$dest"
            elif [[ "$bk_file" == *.zip ]]; then
                unzip -o "$bk_file" -d "$dest" &>/dev/null
            fi
            echo -e "${G}  [+] Restaurado en: $dest${RST}"
            log_audit "RESTAURACION: $(basename "$bk_file") -> $dest"
            ;;
        4)
            echo ""
            if [[ $(ls "$BACKUP_DIR" 2>/dev/null | wc -l) -eq 0 ]]; then
                echo -e "  ${Y}No hay respaldos.${RST}"
            else
                ls -lh "$BACKUP_DIR" 2>/dev/null | tail -n +2 | sed 's/^/  /'
            fi
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# 11. MANTENIMIENTO
# =============================================================================

mantenimiento() {
    banner
    echo -e "${C}  Mantenimiento${RST}\n"
    echo -e "  ${G}1)${RST} Forzar desmontaje (umount -l)"
    echo -e "  ${G}2)${RST} Liberar bloqueos (fuser -km)"
    echo -e "  ${G}3)${RST} Sincronizacion rsync"
    echo -e "  ${G}4)${RST} Estado de servicios"
    echo -e "  ${G}0)${RST} Volver"
    echo ""
    read -rp "  Opcion: " opt

    case $opt in
        1)
            echo ""
            mount | grep "$MOUNT_DIR" 2>/dev/null | awk '{print $3}' | nl -ba | sed 's/^/  /'
            echo ""
            read -rp "  Ruta a forzar desmontaje: " mp_path
            if [[ -n "$mp_path" ]]; then
                echo -e "${Y}  [*] Forzando desmontaje...${RST}"
                umount -l "$mp_path" 2>/dev/null
                if ! mountpoint -q "$mp_path" 2>/dev/null; then
                    rmdir "$mp_path" 2>/dev/null
                    echo -e "${G}  [+] Desmontado.${RST}"
                else
                    fuser -km "$mp_path" 2>/dev/null
                    umount -l "$mp_path" 2>/dev/null
                    echo -e "${Y}  [*] Forzado con fuser.${RST}"
                fi
                log_audit "MANTENIMIENTO: forzar desmontaje $mp_path"
            fi
            ;;
        2)
            echo ""
            local hay=0
            for mp in "$MOUNT_DIR"/*/; do
                [[ -d "$mp" ]] || continue
                local procs=$(fuser -m "$mp" 2>/dev/null)
                if [[ -n "$procs" ]]; then
                    echo -e "  ${R}$mp${RST} -> PIDs: $procs"
                    hay=1
                fi
            done
            [[ $hay -eq 0 ]] && echo -e "  ${G}No hay bloqueos.${RST}"
            if [[ $hay -eq 1 ]]; then
                read -rp "  Matar procesos? (s/n): " resp
                if [[ "$resp" == "s" ]]; then
                    for mp in "$MOUNT_DIR"/*/; do
                        fuser -km "$mp" 2>/dev/null
                    done
                    echo -e "${G}  [+] Procesos liberados.${RST}"
                    log_audit "MANTENIMIENTO: bloqueos liberados"
                fi
            fi
            ;;
        3)
            echo ""
            verificar_dep "rsync" "rsync"
            read -rp "  Origen: " origen
            read -rp "  Destino: " destino
            echo -e "  ${G}1)${RST} Sincronizar (no borrar extras)"
            echo -e "  ${G}2)${RST} Mirror exacto (borrar extras)"
            read -rp "  Modo: " modo_sync

            local rsync_opts="-avz --progress"
            [[ "$modo_sync" == "2" ]] && rsync_opts+=" --delete"

            echo -e "\n${Y}  [*] Ejecutando rsync...${RST}\n"
            rsync $rsync_opts "$origen" "$destino"
            echo -e "\n${G}  [+] Sincronizacion completada.${RST}"
            log_audit "RSYNC: $origen -> $destino"
            ;;
        4)
            echo ""
            for svc in smbd nmbd nfs-kernel-server sshd; do
                local estado=$(systemctl is-active "$svc" 2>/dev/null || echo "no instalado")
                if [[ "$estado" == "active" ]]; then
                    echo -e "  ${G}[+]${RST} $svc: ${G}activo${RST}"
                else
                    echo -e "  ${R}[-]${RST} $svc: ${R}$estado${RST}"
                fi
            done
            ;;
        0) return ;;
    esac
    pausa
}

# =============================================================================
# INICIO
# =============================================================================
menu_principal
