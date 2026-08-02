# Entorno Linux Parrot - Documentacion Completa

Repositorio de configuracion, scripts, herramientas y entorno de escritorio completo sobre Parrot Security OS con bspwm.

---

## Estructura General del Repositorio

```
Copia_Entorno/
├── bspwm/                    # Window Manager (bspwmrc + scripts auxiliares)
├── sxhkd/                    # Atajos de teclado globales
├── polybar/                  # Barra de estado (config, colores, fuentes, scripts)
├── picom/                    # Compositor de ventanas
├── kitty/                    # Emulador de terminal (config + colores)
├── rofi/                     # Lanzador de aplicaciones (config + 20 temas)
├── nvim/                     # Neovim (NvChad - LSP, plugins, mappings)
├── neofetch/                 # Informacion del sistema al abrir terminal
├── zsh/                      # .zshrc original + p10k theme
├── bash/                     # .bashrc + .profile
├── logs/                     # Logs de optimizacion del sistema
├── scripts_estudio/
│   └── 1_Scripts/
│       ├── bash/             # Scripts de practica bash
│       ├── generadores/      # Generadores de datos y passwords
│       ├── go/netaudit/      # Herramienta de auditoria de red (Go)
│       ├── python/           # Scripts Python (redes, calculadora, scanner)
│       └── servicios/        # Aplicativos CLI interactivos de red
├── zshrc                     # .zshrc activo (con aliases y funciones)
├── aplicar_cambios.sh        # Aplica configs al sistema desde el repo
├── reinstalar_entorno.sh     # Reinstala el entorno completo desde cero
├── hardening_ufw.sh          # Hardening basico de firewall
├── install.sh                # Instalador rapido
├── update.sh                 # Actualizador
├── CHANGELOG.md              # Registro de actualizaciones por version
└── README.md                 # Este archivo
```

---

## Entorno de Escritorio (bspwm)

### Configuracion de bspwm

| Parametro | Valor |
|-----------|-------|
| Escritorios | 10 (I - X) |
| Border width | 0 (sin bordes) |
| Window gap | 12px |
| Split ratio | 0.52 |
| Focus follows pointer | Si |
| Fondo de pantalla | feh (~/Desktop/Moskov/Fondo_Pantalla/fondo.jpeg) |
| Compositor | picom |
| Barra | polybar |

### Scripts auxiliares de bspwm

| Script | Funcion |
|--------|---------|
| bspwm_resize | Redimensionar ventanas con atajos |
| ethernet.sh | Modulo de red para polybar |
| infbat.sh | Bateria para polybar |
| restar_Ser.sh | Reiniciar servicios de red |
| target.sh | Mostrar maquina objetivo (HTB/CTF) |
| tlwn722n-monitormode.sh | Poner adaptador WiFi en modo monitor |
| vpn.sh | Estado de VPN para polybar |
| WhichSystem.py | Detectar SO por TTL |
| wifi_conect.py | Conexion WiFi interactiva |
| wifi.sh | Modulo WiFi para polybar |

---

## Atajos de Teclado (sxhkd)

### Generales

| Atajo | Accion |
|-------|--------|
| `Super + Enter` | Abrir terminal (Kitty) |
| `Super + D` | Lanzador de apps (Rofi) |
| `Super + Escape` | Recargar configuracion sxhkd |
| `Super + Q` | Cerrar ventana |
| `Super + Alt + Q` | Cerrar bspwm (logout) |
| `Super + Alt + R` | Reiniciar bspwm |

### Ventanas

| Atajo | Accion |
|-------|--------|
| `Super + T` | Ventana tiled |
| `Super + Shift + T` | Pseudo tiled |
| `Super + S` | Floating |
| `Super + F` | Fullscreen |
| `Super + Flechas` | Mover foco |
| `Super + Shift + Flechas` | Mover ventana |
| `Super + Alt + Flechas` | Redimensionar |
| `Super + M` | Layout monocle |
| `Super + G` | Swap con ventana mas grande |
| `Super + Tab` | Ultimo escritorio |

### Escritorios

| Atajo | Accion |
|-------|--------|
| `Super + 1-9, 0` | Ir a escritorio 1-10 |
| `Super + Shift + 1-9, 0` | Mover ventana a escritorio |
| `Super + [ ]` | Escritorio anterior/siguiente |

### Preseleccion

| Atajo | Accion |
|-------|--------|
| `Super + Ctrl + Alt + Flechas` | Preseleccionar direccion |
| `Super + Ctrl + 1-9` | Ratio de preseleccion |
| `Super + Ctrl + Alt + Espacio` | Cancelar preseleccion |

### Aplicaciones

| Atajo | Accion |
|-------|--------|
| `Super + Shift + F` | Firefox |
| `Super + Shift + G` | Google Chrome |
| `Super + Shift + O` | Tor Browser |
| `Super + Shift + P` | Flameshot (capturas) |
| `Super + Shift + X` | Bloquear pantalla (i3lock-fancy) |

---

## Polybar

### Modulos

- Escritorios bspwm (workspace.ini)
- Reloj/Fecha
- Red (ethernet/wifi)
- Bateria
- VPN
- Target (maquina objetivo)

### Scripts de Polybar

| Script | Funcion |
|--------|---------|
| launcher | Rofi launcher |
| powermenu | Menu de apagado/reinicio/logout |
| powermenu_alt | Alternativo |

### Temas

3 esquemas de color: `colors_dark.ini`, `colors_light.ini`, `colors.ini`

---

## Rofi (Lanzador)

Config: `rofi/.config/rofi/config.rasi`

### Temas disponibles (20)

- launchpad, spotlight, spotlight-dark
- nord, nord-oneline, nord-twoLines
- rounded (blue, gray, green, nord, orange, pink, purple, red, white, yellow) dark
- squared (everforest, material-red, nord)
- windows11 (grid-dark, grid-light, list-dark, list-light)
- simple-tokyonight

---

## Kitty (Terminal)

| Archivo | Contenido |
|---------|-----------|
| kitty.conf | Configuracion principal (fuente, opacidad, padding) |
| color.ini | Esquema de colores personalizado |

---

## Neovim (NvChad)

| Archivo | Funcion |
|---------|---------|
| init.lua | Punto de entrada |
| lua/chadrc.lua | Tema y UI |
| lua/mappings.lua | Keybindings personalizados |
| lua/options.lua | Opciones de editor |
| lua/plugins/init.lua | Plugins adicionales |
| lua/configs/lspconfig.lua | Servidores LSP |
| lua/configs/conform.lua | Formateadores |
| lua/configs/lazy.lua | Gestor de plugins |

---

## Picom (Compositor)

Config: `picom/.config/picom/picom.conf`

Efectos: transparencia, sombras, blur, animaciones de ventana.

---

## Scripts de Servicios de Red

Ubicacion: `scripts_estudio/1_Scripts/servicios/`

Todos se ejecutan con aliases desde cualquier ruta del sistema.

---

### gestionar_compartidos.sh

**Comando:** `compartidos`

Gestor completo de unidades compartidas SMB/NFS/SSHFS.

#### Menu (12 opciones)

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Escanear red | Descubre SMB/NFS con nmap en la subred local |
| 2 | Conectar a unidad | Monta SMB, NFS o SSHFS (valida puertos antes) |
| 3 | Persistencia | Automontaje via /etc/fstab o systemd.mount |
| 4 | Listar/Eliminar | Muestra shares Samba + NFS + montajes. Elimina completo |
| 5 | Crear compartido | Crea carpeta + permisos + comparte en red |
| 6 | Editar compartido | Modifica permisos, usuarios, masks, ruta |
| 7 | Usuarios temporales | Crear, listar, asignar, eliminar usuarios Samba |
| 8 | Diagnostico | Test puertos 445/2049/22/139, ping, lista recursos |
| 9 | Cuotas | Uso de espacio y definir limites con alertas |
| 10 | Monitoreo | smbstatus, ss, log de auditoria |
| 11 | Respaldos | Crear .tar.gz/.zip y restaurar |
| 12 | Mantenimiento | Forzar desmontaje, fuser, rsync, estado servicios |

#### Modos de Acceso (al crear)

| Modo | Comportamiento |
|------|----------------|
| Publico | Acceso anonimo, guest ok, sin credenciales |
| Restringido | Solo usuarios especificos, masks personalizados |
| Predeterminado | Cualquier usuario autenticado, lectura/escritura, proteccion de grupo (chmod 2770, inherit permissions) |

#### Editar Compartido

| # | Accion |
|---|--------|
| 1 | Cambiar read only (lectura / lectura-escritura) |
| 2 | Cambiar create mask / directory mask |
| 3 | Cambiar modo (publico <-> restringido) |
| 4 | Agregar usuario con acceso |
| 5 | Quitar usuario de acceso |
| 6 | Cambiar ruta (con opcion de mover contenido) |

#### Eliminar (opcion 4)

| Accion | Efecto |
|--------|--------|
| es | Quita share de smb.conf + borra carpeta + elimina usuarios + reinicia smbd |
| en | Quita de /etc/exports + borra carpeta + reinicia nfs |
| dm | Desmonta un montaje activo |
| all | Elimina TODO con confirmacion |

---

### startfire.sh

**Comando:** `startfire`

Gestor de Firewall UFW.

| # | Funcion | Descripcion |
|---|---------|-------------|
| 1 | Activar | `ufw --force enable` |
| 2 | Detener | `ufw disable` |
| 3 | Ver Estado | `ufw status verbose` |
| 4 | Permitir Puerto | TCP, UDP o ambos |
| 5 | Bloquear Puerto | Por numero o nombre de servicio |
| 6 | Denegar IP | Todo el trafico o puerto especifico |
| 7 | Eliminar Regla | Por numero (lista numerada) |
| 8 | Reset | Restablecer a default (con confirmacion) |
| 9 | Escaneo Local | Puertos en escucha (ss -tulnp) |

---

### startssh.sh

**Comando:** `startssh`

Gestor de conexiones SSH.

| # | Funcion |
|---|---------|
| 1 | Activar servicio SSH |
| 2 | Detener servicio SSH |
| 3 | Conectar a host remoto |
| 4 | Perfiles guardados |
| 5 | Agregar perfil |
| 6 | Eliminar perfil |
| 7 | Generar llaves SSH (ed25519) |
| 8 | Copiar llave a host remoto |
| 9 | Estado del servicio |

---

### startftp.sh

**Comando:** `startftp`

Gestor de servicio FTP (vsftpd).

| # | Funcion |
|---|---------|
| 1 | Activar FTP |
| 2 | Detener FTP |
| 3 | Estado del servicio |
| 4 | Configuracion vsftpd |
| 5 | Gestion de usuarios |
| 6 | Ver logs |

---

### open_ftp.sh

FTP rapido temporal: crea usuario efimero + abre servidor FTP listo para transferencias.

---

## Scripts de Estudio

### Bash

| Script | Descripcion |
|--------|-------------|
| monitor.sh | Monitor de sistema |
| monitor1.sh | Monitor alternativo |
| restar_Ser.sh | Reiniciar servicios de red |
| unidad_compartida.sh | Compartido basico (version inicial) |

### Python

| Script | Descripcion |
|--------|-------------|
| calculadora.py | Calculadora interactiva |
| estado_pc.py | Estado del PC (CPU, RAM, disco) |
| mostrar_redes.py | Interfaces de red |
| redes.py | Info de red |
| scan_red.py | Scanner de red |
| tuto.py | Script de practica |

### Generadores

| Script | Descripcion |
|--------|-------------|
| Ramdom_password.sh | Generador de passwords aleatorios |
| final.crear.data.py | Generador de datos ficticios |

### Go (netaudit)

Herramienta de auditoria de red compilada en Go.

| Modulo | Funcion |
|--------|---------|
| scanner/ | Escaneo ICMP, ARP, puertos TCP |
| banner/ | Grabbing de banners (SSH, FTP) |
| firewall/ | Reglas UFW y sockets activos |
| report/ | Generacion de reportes (hosts, puertos, auditoria) |
| cli/ | Interfaz de menu, argumentos, tablas, output |
| logger/ | Sistema de logging |

---

## Funciones ZSH (.zshrc)

| Funcion | Uso | Descripcion |
|---------|-----|-------------|
| `refresh` | `refresh` | Recargar .zshrc sin nueva terminal |
| `settarget` | `settarget 10.10.10.1 MiMaquina` | Guardar IP y nombre de objetivo |
| `cleartarget` | `cleartarget` | Limpiar objetivo actual |
| `extractPorts` | `extractPorts scan.gnmap` | Extraer puertos de nmap y copiar al clipboard |
| `whichsystem` | `whichsystem 10.10.10.1` | Detectar SO por TTL |
| `wificonect` | `wificonect` | Conectar a WiFi (interfaz Python) |
| `wifiscan` | `wifiscan` | Poner adaptador en modo monitor |
| `resnet` | `resnet` | Reiniciar servicios de red |
| `mkt` | `mkt` | Crear carpetas CTF (nmap, content, scripts, vpn) |
| `infbat` | `infbat` | Mostrar bateria + fecha/hora |

---

## Aliases

| Alias | Comando Real |
|-------|-------------|
| `cat` | bat |
| `catn` | bat --style=plain |
| `ls` | lsd --group-dirs=first |
| `ll` | lsd -lh --group-dirs=first |
| `la` | lsd -a --group-dirs=first |
| `lla` | lsd -lha --group-dirs=first |
| `cdm` | cd ~/Desktop/Moskov/Ciberseguridad |
| `startftp` | bash .../startftp.sh |
| `startssh` | bash .../startssh.sh |
| `startfire` | bash .../startfire.sh |
| `compartidos` | bash .../gestionar_compartidos.sh |

---

## Scripts de Instalacion

| Script | Funcion |
|--------|---------|
| reinstalar_entorno.sh | Instala TODO desde cero en una maquina nueva (paquetes, configs, entorno) |
| aplicar_cambios.sh | Copia las configs del repo a las rutas del sistema |
| hardening_ufw.sh | Hardening basico (deny incoming, allow SSH/VPN/AnyDesk) |
| install.sh | Instalador rapido |
| update.sh | Actualiza el repo desde el sistema actual |

---

## Datos Operativos (en el sistema, no en el repo)

```
~/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios/
├── FTP/              # Datos del gestor FTP
├── SSH/              # Perfiles guardados SSH
└── Unidades_Compartidas/
    ├── logs/         # auditoria.log
    ├── credenciales/ # Archivos .cred (chmod 600)
    ├── backups/      # Respaldos .tar.gz / .zip
    ├── montajes/     # Puntos de montaje activos
    └── configuracion/# Cuotas, usuarios temporales
```

---

## Estandar de Organizacion

- Carpetas numeradas sin cero: `1_Scripts`, `4_Servicios`
- Rutas sin espacios: guion bajo `Conexiones_Servicios`
- Scripts en `1_Scripts/servicios/`, datos en `4_Servicios/Conexiones_Servicios/`
- Interfaz CLI clasica: banner + menu numerado + read + clear
- Auto-elevacion a root cuando es necesario

---

## Requisitos del Sistema

| Paquete | Uso |
|---------|-----|
| bspwm | Window manager |
| sxhkd | Atajos de teclado |
| polybar | Barra de estado |
| picom | Compositor |
| kitty | Terminal |
| rofi | Lanzador |
| neovim | Editor |
| lsd | Reemplazo de ls |
| bat | Reemplazo de cat |
| feh | Fondo de pantalla |
| nmap | Escaneo de red |
| samba | Compartidos SMB |
| nfs-common | Cliente NFS |
| nfs-kernel-server | Servidor NFS |
| sshfs | Montaje SSH |
| cifs-utils | Montaje SMB |
| ufw | Firewall |
| rsync | Sincronizacion |
| zsh + p10k | Shell + tema |
| fzf | Fuzzy finder |

---

## Actualizaciones

Ver [CHANGELOG.md](CHANGELOG.md) para el historial detallado de cambios.
