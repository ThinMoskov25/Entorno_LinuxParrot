# Entorno Linux Parrot

Repositorio de configuracion, scripts y herramientas del entorno de trabajo en Parrot Security OS.

---

## Estructura del Proyecto

```
Copia_Entorno/
├── bspwm/                          # Window Manager
├── sxhkd/                          # Atajos de teclado
├── polybar/                        # Barra de estado
├── picom/                          # Compositor
├── kitty/                          # Emulador de terminal
├── scripts_estudio/
│   └── 1_Scripts/
│       ├── bash/                   # Scripts de practica
│       ├── generadores/            # Generadores de datos y passwords
│       ├── go/
│       │   └── netaudit/           # Herramienta de auditoria de red (Go)
│       ├── python/                 # Scripts de estudio Python
│       └── servicios/              # Aplicativos interactivos de red
│           ├── gestionar_compartidos.sh
│           ├── startfire.sh
│           ├── startftp.sh
│           ├── startssh.sh
│           └── open_ftp.sh
├── zshrc                           # Configuracion de ZSH
├── CHANGELOG.md                    # Registro de actualizaciones
└── README.md
```

### Carpeta de Datos Operativos (en el sistema)

```
~/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios/
├── FTP/                # Datos del gestor FTP
├── SSH/                # Perfiles y datos SSH
└── Unidades_Compartidas/
    ├── logs/           # Log de auditoria
    ├── credenciales/   # Credenciales SMB (chmod 600)
    ├── backups/        # Respaldos .tar.gz / .zip
    ├── montajes/       # Puntos de montaje activos
    └── configuracion/  # Cuotas, usuarios temporales
```

---

## Scripts de Servicios

Todos los scripts se ejecutan desde cualquier ruta mediante aliases configurados en `.zshrc`.

---

### gestionar_compartidos.sh

**Comando:** `compartidos`

Gestor completo de unidades compartidas en red. Soporta SMB (Samba), NFS y SSHFS.

#### Menu Principal

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Escanear red | Descubre recursos SMB/NFS en la red local con nmap |
| 2 | Conectar a unidad | Monta recursos SMB, NFS o SSHFS con validacion de puertos |
| 3 | Persistencia | Agrega montajes a /etc/fstab o crea unidades systemd.mount |
| 4 | Listar/Desmontar | Muestra compartidos creados y permite eliminarlos completo |
| 5 | Crear compartido | Crea carpeta + permisos + comparte en red (Samba o NFS) |
| 6 | Editar compartido | Modifica permisos, usuarios, masks o ruta de un share existente |
| 7 | Usuarios temporales | Crear, listar, asignar y eliminar usuarios Samba temporales |
| 8 | Diagnostico | Prueba puertos 445/2049/22/139, ping y lista recursos remotos |
| 9 | Cuotas | Ver uso de espacio y definir limites con alertas |
| 10 | Monitoreo | Conexiones activas (smbstatus/ss) y log de auditoria |
| 11 | Respaldos | Crear .tar.gz/.zip y restaurar desde backups |
| 12 | Mantenimiento | Forzar desmontaje, liberar bloqueos, rsync, estado servicios |

#### Modos de Acceso al Crear Compartido

| Modo | Descripcion |
|------|-------------|
| Publico | Acceso anonimo sin credenciales (guest ok) |
| Restringido | Solo usuarios especificos con masks personalizados |
| Predeterminado | Cualquier usuario autenticado, lectura/escritura segura con proteccion de grupo |

#### Editar Compartido (Opcion 6)

| Opcion | Accion |
|--------|--------|
| 1 | Cambiar permisos (solo lectura / lectura-escritura) |
| 2 | Cambiar create mask / directory mask |
| 3 | Cambiar modo (publico <-> restringido) |
| 4 | Agregar usuario con acceso |
| 5 | Quitar usuario de acceso |
| 6 | Cambiar ruta del compartido (con opcion de mover contenido) |

#### Eliminar Compartido (Opcion 4)

| Accion | Que hace |
|--------|----------|
| es | Elimina share de smb.conf + borra carpeta + elimina usuarios temporales + reinicia smbd |
| en | Elimina de /etc/exports + borra carpeta + reinicia nfs-kernel-server |
| dm | Desmonta un montaje activo |
| all | Elimina TODO (shares + exports + montajes + usuarios) con confirmacion |

---

### startfire.sh

**Comando:** `startfire`

Gestor interactivo de Firewall UFW.

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Activar Firewall | `ufw --force enable` |
| 2 | Detener Firewall | `ufw disable` |
| 3 | Ver Estado | Muestra reglas activas con `ufw status verbose` |
| 4 | Permitir Puerto | Permite TCP, UDP o ambos en un puerto especifico |
| 5 | Bloquear Puerto | Bloquea por numero de puerto o nombre de servicio |
| 6 | Denegar IP | Bloquea todo el trafico o un puerto especifico desde una IP |
| 7 | Eliminar Regla | Lista reglas numeradas y elimina por numero |
| 8 | Reset | Restablece UFW a configuracion por defecto (con confirmacion) |
| 9 | Escaneo Local | Muestra puertos en escucha con ss (TCP/UDP) |

---

### startssh.sh

**Comando:** `startssh`

Gestor interactivo de conexiones SSH.

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Activar SSH | Inicia el servicio sshd |
| 2 | Detener SSH | Detiene el servicio |
| 3 | Conectar a host | Conexion SSH interactiva |
| 4 | Perfiles guardados | Lista perfiles almacenados |
| 5 | Agregar perfil | Guarda host/usuario/puerto |
| 6 | Eliminar perfil | Borra un perfil guardado |
| 7 | Generar llaves | Crea par de llaves SSH (ed25519) |
| 8 | Copiar llave | Envia llave publica a host remoto |
| 9 | Estado | Muestra estado del servicio SSH |

---

### startftp.sh

**Comando:** `startftp`

Gestor interactivo de servicio FTP (vsftpd).

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Activar FTP | Inicia vsftpd |
| 2 | Detener FTP | Detiene vsftpd |
| 3 | Estado | Muestra estado del servicio |
| 4 | Configurar | Edita configuracion de vsftpd |
| 5 | Usuarios | Gestiona usuarios FTP |
| 6 | Logs | Muestra logs de conexion |

---

### open_ftp.sh

FTP rapido temporal. Crea un usuario efimero y abre un servidor FTP listo para transferir archivos.

---

## Aliases y Funciones (.zshrc)

```bash
# Servicios de red
alias startftp='bash .../servicios/startftp.sh'
alias startssh='bash .../servicios/startssh.sh'
alias startfire='bash .../servicios/startfire.sh'
alias compartidos='bash .../servicios/gestionar_compartidos.sh'

# Utilidades
function refresh() { source ~/.zshrc; }
function settarget() { ... }     # Guardar IP/nombre de maquina objetivo
function cleartarget() { ... }   # Limpiar objetivo
function extractPorts() { ... }  # Extraer puertos de escaneo nmap
function whichsystem() { ... }   # Detectar SO por TTL
function wificonect() { ... }    # Conectar WiFi
function wifiscan() { ... }      # Monitor mode WiFi
function resnet() { ... }        # Reiniciar servicios de red
function mkt() { ... }           # Crear carpetas de trabajo CTF
function infbat() { ... }        # Info bateria + fecha/hora
```

---

## Requisitos

| Paquete | Uso |
|---------|-----|
| nmap | Escaneo de red |
| samba | Compartidos SMB |
| nfs-common | Cliente NFS |
| nfs-kernel-server | Servidor NFS |
| sshfs | Montaje SSH |
| cifs-utils | Montaje SMB |
| ufw | Firewall |
| rsync | Sincronizacion |
| zip/unzip | Respaldos |

---

## Estandar de Organizacion

- Carpetas sin ceros a la izquierda: `1_Scripts`, `4_Servicios`
- Rutas sin espacios: guion bajo `Conexiones_Servicios`
- Scripts en `1_Scripts/servicios/`, datos operativos en `4_Servicios/Conexiones_Servicios/`
- Todos los scripts se auto-elevan a root cuando es necesario
- Interfaz CLI clasica: banner + menu numerado + prompt + clear entre vistas

---

## Actualizaciones

Ver [CHANGELOG.md](CHANGELOG.md) para el historial detallado de cambios por version.
