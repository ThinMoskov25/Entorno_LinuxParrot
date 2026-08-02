# Contexto del Proyecto para IA (Gemini / Asistentes)

Este archivo contiene toda la informacion necesaria para que una IA entienda el proyecto, su estructura, convenciones y pueda continuar el desarrollo o hacer modificaciones sin perder coherencia.

---

## Informacion General

- **Proyecto:** Entorno Linux Parrot - Configuracion y herramientas de ciberseguridad
- **SO:** Parrot Security OS 6.x (basado en Debian)
- **Usuario:** moskov
- **Home:** /home/moskov
- **Shell:** zsh con Powerlevel10k
- **WM:** bspwm
- **Terminal:** Kitty (/opt/kitty/bin/kitty)
- **Editor:** Neovim (NvChad) en /opt/nvim
- **Repo:** https://github.com/ThinMoskov25/Entorno_LinuxParrot.git
- **Version actual:** v3.0

---

## Estructura del Sistema de Archivos

```
/home/moskov/
├── Desktop/Moskov/
│   ├── Ciberseguridad/
│   │   ├── 1_Scripts/
│   │   │   ├── bash/
│   │   │   ├── python/
│   │   │   ├── generadores/
│   │   │   ├── go/netaudit/
│   │   │   └── servicios/          ← SCRIPTS INTERACTIVOS (aqui va el codigo)
│   │   │       ├── gestionar_compartidos.sh
│   │   │       ├── startfire.sh
│   │   │       ├── startftp.sh
│   │   │       ├── startssh.sh
│   │   │       └── open_ftp.sh
│   │   ├── 2_Laboratorios/
│   │   ├── 3_Herramientas/
│   │   ├── 4_Servicios/
│   │   │   ├── Conexiones_Servicios/   ← DATOS OPERATIVOS (aqui se guardan datos)
│   │   │   │   ├── FTP/
│   │   │   │   ├── SSH/
│   │   │   │   └── Unidades_Compartidas/
│   │   │   │       ├── logs/
│   │   │   │       ├── credenciales/
│   │   │   │       ├── backups/
│   │   │   │       ├── montajes/
│   │   │   │       └── configuracion/
│   │   │   ├── SMTP/
│   │   │   └── ...
│   │   ├── 5_Wordlists/
│   │   ├── 6_Documentos/
│   │   └── 7_VPN/
│   ├── Apps/
│   ├── Fondo_Pantalla/
│   └── Kiro/
├── Desktop/Moskov/Copia_Entorno/    ← REPOSITORIO GIT (copia para GitHub)
├── .config/
│   ├── bspwm/
│   ├── sxhkd/
│   ├── polybar/
│   ├── picom/
│   ├── kitty/
│   ├── rofi/
│   ├── nvim/
│   └── neofetch/
├── .zshrc                           ← Config principal de shell
├── .p10k.zsh
├── powerlevel10k/
└── .fzf/
```

---

## Convencion de Nombres y Rutas

| Regla | Ejemplo |
|-------|---------|
| Sin ceros a la izquierda | `1_Scripts` (NO `01_Scripts`) |
| Sin espacios en rutas | `Conexiones_Servicios` (NO `Conexiones Servicios`) |
| Scripts ejecutables en | `1_Scripts/servicios/` |
| Datos operativos en | `4_Servicios/Conexiones_Servicios/` |
| Aliases en | `~/.zshrc` |

---

## Estilo de los Scripts CLI

Todos los scripts de servicios siguen el mismo patron:

```bash
#!/bin/bash
# Header con descripcion
# Autor: Moskov

# Colores
G="\033[0;32m"; C="\033[0;36m"; Y="\033[1;33m"; R="\033[0;31m"
B="\033[1;37m"; DIM="\033[2m"; RST="\033[0m"

# Rutas
CONEXIONES_ROOT="/home/moskov/Desktop/Moskov/Ciberseguridad/4_Servicios/Conexiones_Servicios"
WORK_DIR="$CONEXIONES_ROOT/<Servicio>"

# Auto-elevacion a root
if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

# Funciones utilitarias
get_ip() { hostname -I | awk '{print $1}'; }
pausa() { read -rp "  Presiona ENTER para continuar..." _; }

# Banner (se llama al inicio de cada vista)
banner() {
    clear
    echo -e "${C}"
    echo "  ========================================================"
    echo "       TITULO - NombreScript"
    echo "  ========================================================"
    echo "   Descripcion corta"
    echo "  ========================================================"
    echo -e "${RST}"
}

# Menu principal (bucle recursivo)
menu_principal() {
    banner
    # Estado del servicio
    echo -e "  ${DIM}IP Local: $(get_ip)${RST}"
    echo -e "  ${G}[+] SERVICIO ACTIVO${RST}\n"
    # Opciones numeradas
    echo -e "  ${G}1)${RST} Opcion uno"
    echo -e "  ${G}2)${RST} Opcion dos"
    echo -e "  ${G}0)${RST} Salir"
    echo ""
    read -rp "  Opcion: " opt
    case $opt in
        1) funcion_uno ;;
        2) funcion_dos ;;
        0) echo -e "\n${G}  Hasta luego!${RST}\n"; exit 0 ;;
        *) echo -e "${R}  [!] Opcion no valida${RST}"; sleep 1 ;;
    esac
    menu_principal  # Bucle
}

# Funciones individuales
funcion_uno() {
    banner
    echo -e "${C}  Titulo de la funcion${RST}\n"
    # ... logica ...
    pausa
}

# Inicio
menu_principal
```

### Reglas de interfaz:
- `clear` al inicio de cada vista (dentro de `banner()`)
- Menu numerado con `read -rp "  Opcion: "`
- Colores: verde=exito, amarillo=proceso, rojo=error, cyan=titulo, dim=info secundaria
- `pausa` al final de cada operacion antes de volver
- Mensajes con formato: `[+]` exito, `[*]` proceso, `[!]` error/aviso
- Indentacion de 4 espacios en el contenido visible

---

## Aliases Configurados (.zshrc)

```bash
alias startftp='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startftp.sh'
alias startssh='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startssh.sh'
alias startfire='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startfire.sh'
alias compartidos='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/gestionar_compartidos.sh'
```

Al crear un nuevo script de servicio:
1. Crear el archivo en `1_Scripts/servicios/`
2. `chmod +x` al archivo
3. Agregar alias en `~/.zshrc` en la seccion "Servicios de red"
4. El alias NO lleva `sudo` (el script se auto-eleva)

---

## Scripts Existentes y sus Comandos

| Script | Alias | Funcion |
|--------|-------|---------|
| gestionar_compartidos.sh | `compartidos` | Gestor SMB/NFS/SSHFS (12 opciones) |
| startfire.sh | `startfire` | Gestor Firewall UFW (9 opciones) |
| startssh.sh | `startssh` | Gestor SSH (9 opciones) |
| startftp.sh | `startftp` | Gestor FTP vsftpd |
| open_ftp.sh | - | FTP rapido temporal |

---

## Funciones ZSH Personalizadas

| Funcion | Descripcion |
|---------|-------------|
| refresh() | source ~/.zshrc |
| settarget IP NOMBRE | Guardar maquina objetivo |
| cleartarget() | Limpiar target |
| extractPorts ARCHIVO | Extraer puertos de nmap al clipboard |
| whichsystem IP | Detectar SO por TTL |
| wificonect() | Conectar WiFi (Python) |
| wifiscan ARGS | Modo monitor WiFi |
| resnet() | Reiniciar servicios de red |
| mkt() | Crear carpetas CTF |
| infbat() | Bateria + fecha |

---

## Atajos de Teclado (sxhkd)

| Atajo | Accion |
|-------|--------|
| Super + Enter | Terminal (Kitty) |
| Super + D | Rofi (lanzador) |
| Super + Q | Cerrar ventana |
| Super + F | Fullscreen |
| Super + S | Floating |
| Super + T | Tiled |
| Super + 1-0 | Escritorios |
| Super + Shift + 1-0 | Mover ventana a escritorio |
| Super + Flechas | Mover foco |
| Super + Shift + Flechas | Mover ventana |
| Super + Alt + Flechas | Redimensionar |
| Super + Shift + F | Firefox |
| Super + Shift + G | Chrome |
| Super + Shift + O | Tor Browser |
| Super + Shift + P | Flameshot (screenshot) |
| Super + Shift + X | i3lock (bloquear) |
| Super + Alt + Q | Cerrar bspwm |
| Super + Alt + R | Reiniciar bspwm |
| Super + Escape | Recargar sxhkd |

---

## Flujo de Trabajo para Nuevos Scripts

1. Crear en `~/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/nombre.sh`
2. Seguir la plantilla de estilo CLI (banner + menu + case + pausa)
3. Si necesita datos persistentes: crear subcarpeta en `4_Servicios/Conexiones_Servicios/`
4. `chmod +x` al script
5. Agregar alias en `~/.zshrc`
6. Para subir a GitHub:
   - Copiar script a `~/Desktop/Moskov/Copia_Entorno/scripts_estudio/1_Scripts/servicios/`
   - `cd ~/Desktop/Moskov/Copia_Entorno`
   - `git add . && git commit -m "descripcion" && git push origin main`

---

## Notas Importantes

- El sistema usa Parrot Security (Debian-based), paquetes con `apt`
- Los scripts se auto-elevan con `exec sudo bash "$0" "$@"` (no poner sudo en el alias)
- La terminal es Kitty con TERM=xterm-kitty (puede necesitar fallback a xterm-256color)
- El repo en GitHub es `Copia_Entorno/` (mirror del entorno, no el entorno en vivo)
- Nunca usar espacios en nombres de carpetas
- Numeracion sin ceros: 1, 2, 3... no 01, 02, 03
