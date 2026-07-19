# Entorno Completo - Parrot Security 6.3 (moskov)

## Contenido

```
Copia_Entorno/
├── reinstalar_entorno.sh   # Instala TODO desde cero en una VM/PC nueva
├── install.sh              # Solo enlaza dotfiles con stow (si ya tienes paquetes)
├── aplicar_cambios.sh      # Aplica optimizaciones (stow + ufw + picom + sxhkd)
├── hardening_ufw.sh        # Solo configura firewall UFW
├── update.sh               # Crea el comando global 'update' con snapshot + upgrade
├── logs/                   # Historial de ejecuciones
├── zsh/                    # .zshrc + .p10k.zsh
├── bash/                   # .bashrc + .profile
├── bspwm/                  # bspwmrc + scripts (target, wifi, vpn, resize, etc.)
├── sxhkd/                  # Atajos de teclado
├── kitty/                  # Terminal config + colores
├── picom/                  # Compositor (blur, sombras, esquinas)
├── polybar/                # Barra de estado + fuentes + scripts
├── rofi/                   # Launcher + temas
├── nvim/                   # NvChad completo
└── neofetch/               # Config de neofetch
```

---

## Funciones Personalizadas

Funciones disponibles en el shell (definidas en `.zshrc`). Se ejecutan escribiendo el nombre en la terminal.

| Funcion | Uso | Descripcion |
|---------|-----|-------------|
| `settarget` | `settarget 10.10.10.1 MiMaquina` | Guarda la IP y nombre del target actual para pentesting. Se muestra en polybar. |
| `cleartarget` | `cleartarget` | Limpia el target actual (polybar muestra "No target"). |
| `extractPorts` | `extractPorts allPorts.gnmap` | Extrae puertos abiertos de un escaneo nmap, los muestra con formato y los copia al clipboard. |
| `whichsystem` | `whichsystem 10.10.10.1` | Identifica el sistema operativo de un host basandose en el TTL (Linux/Windows). |
| `mkt` | `mkt` | Crea la estructura de carpetas estandar para pentesting: nmap, content, scripts, vpn. |
| `wificonect` | `wificonect` | Ejecuta script Python para conectarse a una red WiFi. |
| `wifiscan` | `wifiscan` | Pone el adaptador TL-WN722N en modo monitor para escaneo WiFi. |
| `resnet` | `resnet` | Reinicia los servicios de red del sistema. |
| `infbat` | `infbat` | Muestra fecha, hora y estado de bateria (porcentaje + cargando/descargando) en verde. |

---

## Comandos Globales

Comandos disponibles desde cualquier directorio (instalados en `/usr/local/bin/`).

| Comando | Descripcion |
|---------|-------------|
| `update` | Crea un snapshot con Timeshift + actualiza el sistema con `parrot-upgrade`. Logs en `~/Desktop/Moskov/Apps/Update/logs/`. |

---

## Aliases

| Alias | Equivale a | Descripcion |
|-------|-----------|-------------|
| `cat` | `bat` | Visor de archivos con syntax highlighting |
| `catn` | `bat --style=plain` | Cat sin decoraciones |
| `catnp` | `bat --style=plain --paging=never` | Cat sin paginador |
| `ls` | `lsd --group-dirs=first` | Listado con iconos |
| `ll` | `lsd -lh --group-dirs=first` | Listado largo |
| `la` | `lsd -a --group-dirs=first` | Listado incluyendo ocultos |
| `lla` | `lsd -lha --group-dirs=first` | Listado largo + ocultos |
| `cdm` | `cd $HOME/Desktop/Moskov/Ciberseguridad` | Ir al directorio de trabajo principal |

---

## Atajos de Teclado (sxhkd)

| Atajo | Accion |
|-------|--------|
| `Super + Return` | Abrir Kitty (terminal) |
| `Super + d` | Abrir Rofi (launcher) |
| `Super + q` | Cerrar ventana |
| `Super + f` | Fullscreen |
| `Super + s` | Floating |
| `Super + t` | Tiled |
| `Super + m` | Monocle layout |
| `Super + Flechas` | Mover foco |
| `Super + Shift + Flechas` | Mover ventana |
| `Super + Alt + Flechas` | Redimensionar ventana |
| `Super + Alt + q` | Salir de bspwm |
| `Super + Alt + r` | Reiniciar bspwm |
| `Super + Escape` | Recargar sxhkd |

---

## Uso rapido

### Reinstalar entorno completo en una maquina nueva

```bash
git clone <este-repo> ~/dotfiles
sudo bash ~/dotfiles/reinstalar_entorno.sh
# Reiniciar > seleccionar bspwm > listo
```

### Solo enlazar configs (si ya tienes los paquetes)

```bash
sudo apt install stow -y
cd ~/dotfiles
./install.sh
```

### Solo firewall

```bash
sudo bash hardening_ufw.sh
```

### Solo crear comando 'update'

```bash
sudo bash update.sh
```

## Que instala reinstalar_entorno.sh

1. Actualiza sistema (apt update/upgrade)
2. bspwm + sxhkd + polybar + picom + rofi + feh + wmname
3. zsh + powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting
4. bat + lsd + fzf + stow + xclip
5. Kitty (terminal, instalada en /opt/)
6. Neovim + NvChad (editor, en /opt/)
7. Herramientas de seguridad: nmap, metasploit, burpsuite, wireshark, aircrack-ng, hashcat, john, hydra, sqlmap, nikto, gobuster, ffuf, responder, wifite, impacket, pspy
8. Enlaza todos los dotfiles con stow
9. UFW firewall (deny in, allow out, SSH/AnyDesk/VPN permitidos)
10. Crea estructura de carpetas de trabajo
11. Crea comando global 'update' (timeshift snapshot + parrot-upgrade)

## Notas

- Wallpaper: copiar a ~/Desktop/Moskov/Fondo_Pantalla/fondo.jpeg
- Fuente terminal: HackNerdFont (descargar de nerdfonts.com si no viene)
- Rofi theme: squared-nord
- Los paths usan $HOME, es portable a cualquier usuario
