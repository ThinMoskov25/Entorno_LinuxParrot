# Entorno Completo - Parrot Security 6.3 (Moskov)

Repositorio para reinstalar y replicar el entorno completo de trabajo en cualquier maquina o VM.

## Estructura del repositorio

```
.
├── reinstalar_entorno.sh       # Instala TODO desde cero (un solo comando)
├── install.sh                  # Solo enlaza dotfiles con stow
├── aplicar_cambios.sh          # Aplica optimizaciones post-instalacion
├── hardening_ufw.sh            # Configura firewall UFW
├── update.sh                   # Crea el comando global 'update'
├── README.md                   # Este archivo
│
├── zsh/                        # .zshrc + .p10k.zsh
├── bash/                       # .bashrc + .profile
├── bspwm/                      # bspwmrc + scripts de polybar y sistema
├── sxhkd/                      # Atajos de teclado
├── kitty/                      # Terminal (config + colores)
├── picom/                      # Compositor (blur, sombras, esquinas redondeadas)
├── polybar/                    # Barra de estado + fuentes + powermenu
├── rofi/                       # Launcher + temas
├── nvim/                       # NvChad config completa
├── neofetch/                   # Config neofetch
│
└── scripts_estudio/            # Scripts propios de ciberseguridad
    ├── python/                 # calculadora, estado_pc, redes, scan_red, mostrar_redes
    ├── bash/                   # monitor mode, restar_Ser, unidad_compartida
    ├── servicios/              # startftp, startssh, open_ftp
    ├── generadores/            # crear_data (Excel), random_password
    ├── smtp_conf2.py           # Gestor SMTP interactivo
    └── smtp_crear_pass.py      # Creador seguro de credenciales SMTP
```

---

## Uso rapido

### Reinstalar entorno completo en una maquina nueva

```bash
git clone https://github.com/ThinMoskov25/Entorno_LinuxParrot.git ~/dotfiles
sudo bash ~/dotfiles/reinstalar_entorno.sh
# Reiniciar > seleccionar bspwm en el login > listo
```

### Solo enlazar dotfiles (si ya tienes paquetes instalados)

```bash
sudo apt install stow -y
cd ~/dotfiles && ./install.sh
```

---

## Que instala reinstalar_entorno.sh

| Paso | Componente |
|------|-----------|
| 1 | Actualiza sistema (apt update/upgrade) |
| 2 | bspwm + sxhkd + polybar + picom + rofi + feh + wmname |
| 3 | zsh + powerlevel10k + autosuggestions + syntax-highlighting + sudo plugin |
| 4 | bat + lsd + fzf + stow + xclip |
| 5 | Kitty (terminal en /opt/) |
| 6 | Neovim + NvChad (editor en /opt/) |
| 7 | Herramientas: nmap, metasploit, burpsuite, wireshark, aircrack-ng, hashcat, john, hydra, sqlmap, nikto, gobuster, ffuf, responder, wifite, impacket, pspy |
| 8 | Enlaza dotfiles con stow |
| 9 | UFW firewall (deny in, allow out, SSH/AnyDesk/VPN) |
| 10 | Crea estructura de carpetas + copia scripts |
| 11 | Comando global 'update' (timeshift + parrot-upgrade) |
| 12 | pyftpdlib (dependencia de startftp) |

---

## Estructura de Ciberseguridad (en la maquina)

```
~/Desktop/Moskov/Ciberseguridad/
├── 01_Scripts/
│   ├── python/         Scripts Python propios
│   ├── bash/           Scripts Bash propios
│   ├── servicios/      startftp.sh, startssh.sh
│   ├── generadores/    Crear datos y passwords
│   └── go/             Proyectos Go (netaudit)
├── 02_Laboratorios/
│   ├── Redes/capturas/ Capturas de lab
│   ├── HTB/            Maquinas HackTheBox
│   └── Network_Drive/  Samba compartido
├── 03_Herramientas/
│   ├── Escaneo/        cybertool, ngrok
│   ├── WiFi/           tlwn722n, wifi_conect
│   ├── Phishing/       zphisher, PyPhisher
│   ├── Movil/          ADB-Toolkit
│   ├── OSINT/          GHunt, Mr_HOLMES
│   └── Instaladores/   Parrot-Tools, hackingtool
├── 04_Servicios/
│   ├── SMTP/           Configuracion + logs
│   ├── FTP/            Logs del servidor
│   └── SSH/            Perfiles de conexion
├── 05_Wordlists/       Diccionarios (rockyou, etc.)
├── 06_Documentos/      Notas y apuntes
└── 07_VPN/
    ├── HTB/            .ovpn de HackTheBox
    └── TPLink/         VPN del router
```

---

## Funciones disponibles en terminal

| Funcion | Uso | Descripcion |
|---------|-----|-------------|
| `settarget` | `settarget 10.10.10.1 Box` | Guarda target actual (se muestra en polybar) |
| `cleartarget` | `cleartarget` | Limpia el target |
| `extractPorts` | `extractPorts allPorts.gnmap` | Extrae puertos de nmap y copia al clipboard |
| `whichsystem` | `whichsystem 10.10.10.1` | Identifica OS por TTL |
| `mkt` | `mkt` | Crea carpetas: nmap, content, scripts, vpn |
| `wificonect` | `wificonect` | Conectar WiFi via script |
| `wifiscan` | `wifiscan` | Modo monitor TL-WN722N |
| `resnet` | `resnet` | Reiniciar servicios de red |
| `infbat` | `infbat` | Muestra fecha/hora + bateria (verde) |
| `startftp` | `startftp` | Aplicativo interactivo para servidor FTP |
| `startssh` | `startssh` | Aplicativo interactivo para conexiones SSH |
| `compartidos` | `compartidos` | Gestor de carpetas compartidas (Samba) |
| `netaudit` | `netaudit` | Herramienta de auditoria de red (menu interactivo) |
| `netscan` | `netscan discover/scan/banner/audit` | NetAudit en modo comando directo |

---

## Comandos globales

| Comando | Descripcion |
|---------|-------------|
| `update` | Crea snapshot Timeshift + actualiza sistema. Logs en ~/Desktop/Moskov/Apps/Update/logs/ |

---

## Aliases

| Alias | Equivale a |
|-------|-----------|
| `cat` | `bat` |
| `catn` | `bat --style=plain` |
| `ls` | `lsd --group-dirs=first` |
| `ll` | `lsd -lh --group-dirs=first` |
| `la` | `lsd -a --group-dirs=first` |
| `lla` | `lsd -lha --group-dirs=first` |
| `cdm` | `cd ~/Desktop/Moskov/Ciberseguridad` |

---

## Atajos de teclado (sxhkd + bspwm)

| Atajo | Accion |
|-------|--------|
| `Super + Return` | Kitty (terminal) |
| `Super + d` | Rofi (launcher) |
| `Super + q` | Cerrar ventana |
| `Super + f` | Fullscreen |
| `Super + s` | Floating |
| `Super + t` | Tiled |
| `Super + m` | Monocle layout |
| `Super + Flechas` | Mover foco |
| `Super + Shift + Flechas` | Mover ventana |
| `Super + Alt + Flechas` | Redimensionar |
| `Super + Alt + q` | Salir de bspwm |
| `Super + Alt + r` | Reiniciar bspwm |
| `Super + Escape` | Recargar sxhkd |

---

## Powermenu (boton de power en polybar)

| Opcion | Accion |
|--------|--------|
| Lock | i3lock-fancy |
| Sleep | systemctl suspend |
| Logout | bspc quit |
| Restart | systemctl reboot |
| Shutdown | systemctl poweroff |

---

## Notas

- Wallpaper: copiar a `~/Desktop/Moskov/Fondo_Pantalla/fondo.jpeg`
- Fuente: HackNerdFont (descargar de nerdfonts.com)
- Tema Rofi: squared-nord
- Todos los paths son absolutos a `/home/moskov` (no usan $HOME para evitar conflictos con root)
- El powermenu requiere altura 260px para mostrar las 5 opciones

---

## NetAudit (Go)

Herramienta de auditoria de red escrita en Go. Ubicada en `scripts_estudio/01_Scripts/go/netaudit/`.

**Comandos disponibles:**
| Comando | Descripcion |
|---------|-------------|
| `netaudit` | Menu interactivo completo |
| `netscan discover` | Descubrir hosts en la red local |
| `netscan scan` | Escanear puertos de un host |
| `netscan banner` | Capturar banners de servicios |
| `netscan sockets` | Listar sockets abiertos |
| `netscan firewall` | Revisar reglas de firewall |
| `netscan audit` | Auditoria completa |

**Compilar:**
```bash
cd ~/Desktop/Moskov/Ciberseguridad/01_Scripts/go/netaudit
go build -o netaudit .
```
