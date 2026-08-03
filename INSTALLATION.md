# Guia de Instalacion - Moskov Environment v3.0

---

## Requisitos

- **SO:** Parrot Security OS 6.x / Debian 12+
- **Arquitectura:** x86_64
- **RAM:** 2 GB minimo (4 GB recomendado)
- **Disco:** 15 GB libres
- **Red:** Conexion a internet activa
- **Modo:** Puede ejecutarse desde TTY o sesion grafica

---

## Instalacion Rapida (1 comando)

```bash
sudo parrot-upgrade && sudo apt install -y git && \
git clone https://github.com/ThinMoskov25/Entorno_LinuxParrot.git /tmp/entorno && \
sudo bash /tmp/entorno/install_environment.sh --auto
```

Despues de completar, reiniciar:

```bash
sudo reboot
```

---

## Opciones de Ejecucion

### Modo Automatico (desatendido)

```bash
sudo bash install_environment.sh --auto
```

Instala todo sin preguntas. Ideal para despliegue limpio desde snapshot.

### Modo Interactivo (menu)

```bash
sudo bash install_environment.sh
```

Muestra un menu con opciones para instalar por fases.

### Forzar usuario especifico

Si la deteccion automatica falla (ej: ejecutando desde `su - root`):

```bash
sudo bash install_environment.sh --auto --user=nombre_usuario
```

---

## Fases de Instalacion

| Fase | Descripcion |
|------|-------------|
| 0 - Pre-flight | Saneamiento APT/DPKG: mata procesos, limpia candados, repara base |
| 1 - Sistema | Detecta sesion grafica, configura Xorg/LightDM |
| 2 - Paquetes | Instala WM, shell, dev tools, seguridad, utilidades |
| 3 - Sesion | Despliega bspwm-session, .desktop, configura LightDM |
| 4 - Binarios | Kitty, Neovim, Powerlevel10k, fzf, plugin sudo zsh |
| 5 - Herramientas | i3lock-fancy, impacket, pspy, rofi-themes, ngrok, evil-winrm |
| 6 - Despliegue | Copia configs, scripts, Apps, wallpaper, dotfiles, post_config.sh |
| 7 - Permisos | chown, chmod +x, P10k root, enlace de scripts en PATH |
| 8 - Seguridad | UFW, update command, LightDM enable |

---

## Deteccion de Usuario

El script detecta automaticamente el usuario real (no root) con esta prioridad:

1. Parametro `--user=nombre` (override explicito)
2. Variable `$SUDO_USER`
3. Comando `logname`
4. Salida de `who` (excluyendo root)
5. Propietario del directorio del script (quien hizo `git clone`)
6. Primer usuario con UID >= 1000 en `/etc/passwd`

---

## Estructura Desplegada

Despues de la instalacion, el sistema queda:

```
~/Desktop/USUARIO/
├── Apps/                    Scripts de instalacion de aplicaciones
│   ├── 7zip/
│   ├── Anydesk/
│   ├── Google_Chrome/
│   ├── Keepass/
│   ├── Kiro/
│   ├── Nmap/
│   ├── Opera_X/
│   ├── Putty/
│   ├── Remote_Control/
│   ├── Telegram/
│   ├── Thor_Onion/
│   ├── Update/              Comando 'update' + logs
│   ├── Visual_Code/
│   └── WPS_Office/
├── Ciberseguridad/
│   ├── 1_Scripts/           bash, python, go, servicios
│   ├── 2_Laboratorios/      Redes, HTB, Network_Drive
│   ├── 3_Herramientas/      Escaneo, WiFi, OSINT, Phishing
│   ├── 4_Servicios/         FTP, SSH, Samba, SMTP
│   ├── 5_Wordlists/
│   ├── 6_Documentos/
│   └── 7_VPN/              HTB, TPLink
├── Fondo_Pantalla/
├── Kiro/
└── post_config.sh           Configuracion post-instalacion

~/.config/
├── bspwm/                   WM config + scripts polybar
├── sxhkd/                   Atajos de teclado
├── polybar/                 Barra + temas + fuentes
├── picom/                   Compositor
├── kitty/                   Terminal
├── rofi/                    Launcher + temas
├── nvim/                    Editor (NvChad)
├── neofetch/                Info sistema
└── bin/target               Archivo de target para polybar
```

---

## Post-Instalacion

Despues de reiniciar y entrar a la sesion BSPWM:

```bash
bash ~/Desktop/$(whoami)/post_config.sh
```

| Opcion | Funcion |
|--------|---------|
| 1 | Configurar Powerlevel10k (wizard, replicar, root) |
| 2 | Instalar Apps desde ~/Desktop/usuario/Apps/ |
| 3 | Configurar interfaces de red |
| 4 | Validar scripts y funciones |
| 5 | Ver todas las funciones y comandos disponibles |

---

## Comando Update (con Snapshot)

Despues de instalar Apps/Update:

```bash
sudo update
```

Este comando:
1. Crea snapshot automatica con Timeshift
2. Ejecuta `parrot-upgrade -y`
3. Guarda log en `~/Desktop/usuario/Apps/Update/logs/`

---

## Solucion de Problemas

### LightDM no muestra sesion BSPWM
```bash
cat /usr/share/xsessions/bspwm.desktop
cat /usr/bin/bspwm-session
```

### bspwm arranca pero sin keybindings
```bash
cat ~/install_logs/bspwm-session.log
which sxhkd
```

### Funciones no disponibles (command not found)
```bash
source ~/.zshrc
```
Los scripts de servicios se acceden via aliases, NO via PATH:
- `startftp` — Gestor FTP
- `startssh` — Gestor SSH
- `startfire` — Gestor Firewall (requiere sudo)
- `compartidos` — Gestor Samba (requiere sudo)

### "Recurso no disponible temporalmente" (fork bomb)
Si ocurre, eliminar symlinks residuales:
```bash
rm -f ~/.local/bin/gestionar_compartidos ~/.local/bin/startftp
rm -f ~/.local/bin/startssh ~/.local/bin/startfire ~/.local/bin/open_ftp
```
Esto fue corregido en v3.0 final — no deberia ocurrir en instalaciones nuevas.

### P10k no carga
```bash
p10k configure
```

---

## Logs

| Log | Ubicacion |
|-----|-----------|
| Instalacion | `~/install_logs/install_FECHA.log` |
| Sesion BSPWM | `~/install_logs/bspwm-session.log` |
| Updates | `~/Desktop/usuario/Apps/Update/logs/` |
| Samba | `~/Desktop/usuario/Ciberseguridad/4_Servicios/.../samba.log` |
