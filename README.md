# Entorno Linux Parrot - v3.0

Repositorio de configuracion, scripts y herramientas del entorno de trabajo en Parrot Security OS.

## Estructura del Proyecto

```
Copia_Entorno/
├── bspwm/                    # Configuracion de bspwm (WM)
├── sxhkd/                    # Atajos de teclado
├── polybar/                  # Barra de estado
├── picom/                    # Compositor
├── kitty/                    # Terminal
├── scripts_estudio/
│   └── 1_Scripts/
│       ├── bash/             # Scripts de practica bash
│       ├── generadores/      # Generadores de datos
│       ├── go/               # Scripts en Go
│       ├── python/           # Scripts en Python
│       └── servicios/        # Aplicativos interactivos de red
│           ├── gestionar_compartidos.sh   # Gestor de Unidades Compartidas
│           ├── startfire.sh               # Gestor de Firewall (UFW)
│           ├── startftp.sh                # Gestor de servicio FTP
│           ├── startssh.sh                # Gestor de conexiones SSH
│           └── open_ftp.sh                # FTP rapido temporal
├── zshrc                     # Configuracion de ZSH
└── README.md
```

## Scripts de Servicios de Red

### gestionar_compartidos.sh (alias: `compartidos`)

Gestor completo de unidades compartidas en red (SMB/NFS/SSHFS).

**Funcionalidades:**
- Escaneo de red para descubrir recursos compartidos
- Montaje de unidades SMB, NFS y SSHFS con validacion de puertos
- Persistencia de montajes (fstab / systemd.mount)
- Creacion de compartidos Samba y NFS con 3 modos de acceso:
  - Publico (anonimo)
  - Restringido (usuarios especificos)
  - Predeterminado (cualquier usuario autenticado, lectura/escritura segura)
- Edicion de compartidos existentes (permisos, usuarios, masks, ruta)
- Gestion de usuarios temporales (crear, asignar, eliminar)
- Eliminacion completa de compartidos (share + carpeta + usuarios + servicio)
- Diagnostico de conectividad (puertos 445, 2049, 22, 139)
- Gestion de cuotas y espacio
- Monitoreo en tiempo real y log de auditoria
- Respaldos (.tar.gz / .zip) y restauracion
- Mantenimiento (forzar desmontaje, liberar bloqueos, rsync)

**Ruta de datos:** `Ciberseguridad/4_Servicios/Conexiones_Servicios/Unidades_Compartidas/`

---

### startfire.sh (alias: `startfire`)

Gestor interactivo de Firewall UFW.

**Funcionalidades:**
- Activar / Detener UFW
- Ver estado y reglas activas (verbose)
- Permitir puerto (TCP / UDP / ambos)
- Bloquear puerto o servicio por nombre
- Denegar IP especifica (todo o puerto concreto)
- Eliminar regla por numero
- Reset completo a valores por defecto
- Escaneo rapido de puertos locales en escucha (ss)

---

### startssh.sh (alias: `startssh`)

Gestor interactivo de conexiones SSH.

**Funcionalidades:**
- Activar / Detener servicio SSH
- Conectar a host remoto
- Perfiles guardados (agregar, listar, eliminar)
- Generar llaves SSH
- Copiar llave a host remoto
- Estado del servicio

**Ruta de datos:** `Ciberseguridad/4_Servicios/Conexiones_Servicios/SSH/`

---

### startftp.sh (alias: `startftp`)

Gestor interactivo de servicio FTP (vsftpd).

**Funcionalidades:**
- Activar / Detener servicio FTP
- Configuracion de vsftpd
- Gestion de usuarios FTP
- Monitoreo de conexiones

**Ruta de datos:** `Ciberseguridad/4_Servicios/Conexiones_Servicios/FTP/`

---

## Estandar de Organizacion

### Carpeta Conexiones_Servicios

Todos los scripts de servicios de red almacenan sus datos operativos en:
```
~/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios/
├── FTP/
├── SSH/
└── Unidades_Compartidas/
    ├── logs/
    ├── credenciales/
    ├── backups/
    ├── montajes/
    └── configuracion/
```

### Nomenclatura de carpetas
- Sin ceros a la izquierda: `1_Scripts`, `4_Servicios` (no `01_Scripts`)
- Sin espacios: usar guion bajo `Conexiones_Servicios`

## Aliases (.zshrc)

```bash
alias startftp='bash .../1_Scripts/servicios/startftp.sh'
alias startssh='bash .../1_Scripts/servicios/startssh.sh'
alias startfire='bash .../1_Scripts/servicios/startfire.sh'
alias compartidos='bash .../1_Scripts/servicios/gestionar_compartidos.sh'
```

Funcion `refresh` para recargar la configuracion de zsh sin abrir nueva terminal.

## Requisitos

- Parrot Security OS / Debian-based
- Paquetes: `nmap`, `samba`, `nfs-common`, `nfs-kernel-server`, `sshfs`, `cifs-utils`, `ufw`
- Ejecucion como root (los scripts se auto-elevan con sudo)

## Changelog

### v3.0 (2026-07-21)
- Nuevo: `gestionar_compartidos.sh` - Gestor completo de unidades compartidas
- Nuevo: `startfire.sh` - Gestor de Firewall UFW
- Nuevo: Modo predeterminado seguro para compartidos Samba
- Nuevo: Edicion de compartidos existentes (permisos, usuarios, masks)
- Nuevo: Eliminacion completa (share + carpeta + usuario + servicio)
- Corregido: Estructura de carpetas sin ceros (01_ -> 1_)
- Corregido: Rutas sin espacios (Conexiones_Servicios)
- Actualizado: startftp.sh, startssh.sh, open_ftp.sh usan nueva ruta estandar
- Actualizado: .zshrc con aliases startfire, compartidos y funcion refresh

### v2.1
- Sync: netaudit, gestionar_compartidos inicial, powermenu

### v2.0
- Reorganizacion completa, nueva estructura, README documentado
