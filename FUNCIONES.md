# Funciones, Aliases y Atajos - Moskov Environment v3.0

---

## 1. Funciones ZSH (definidas en ~/.zshrc)

| Funcion | Descripcion | Uso |
|---------|-------------|-----|
| `refresh` | Recarga .zshrc sin cerrar terminal | `refresh` |
| `settarget` | Establece target (IP + nombre) en polybar | `settarget 10.10.10.5 MetaTwo` |
| `cleartarget` | Limpia el target configurado | `cleartarget` |
| `wificonect` | Menu interactivo Python para WiFi (nmcli) | `wificonect` |
| `wifiscan` | Modo monitor para TL-WN722N | `wifiscan` |
| `resnet` | Restaura servicios de red (NM + wpa_supplicant) | `resnet` |
| `mkt` | Crea dirs pentesting: nmap/ content/ scripts/ vpn/ | `mkt` |
| `whichsystem` | Detecta SO por TTL (ping) | `whichsystem 10.10.10.5` |
| `extractPorts` | Extrae puertos de nmap grepable + copia clipboard | `extractPorts allPorts.gnmap` |
| `infbat` | Muestra fecha/hora + bateria en verde | `infbat` |
| `netaudit` | Auditoria de red interactiva (binario Go) | `netaudit` |
| `netscan` | Auditoria de red modo directo | `netscan discover 192.168.1.0/24` |

---

## 2. Aliases de Servicios

| Alias | Que ejecuta | Requiere sudo |
|-------|-------------|:---:|
| `startftp` | Gestor FTP interactivo (pyftpdlib) | No |
| `startssh` | Gestor SSH (conexiones/perfiles/llaves) | No |
| `startfire` | Gestor Firewall UFW | Si |
| `compartidos` | Gestor Samba v6.0 | Si |
| `cdm` | `cd ~/Desktop/usuario/Ciberseguridad` | No |
| `update` | Snapshot timeshift + parrot-upgrade | Si |

---

## 3. Aliases Utiles

| Alias | Comando real |
|-------|-------------|
| `cat` | `bat` (sintaxis resaltada) |
| `catn` | `bat --style=plain` |
| `catnp` | `bat --style=plain --paging=never` |
| `ls` | `lsd --group-dirs=first` |
| `ll` | `lsd -lh --group-dirs=first` |
| `la` | `lsd -a --group-dirs=first` |
| `lla` | `lsd -lha --group-dirs=first` |
| `l` | `lsd --group-dirs=first` |

---

## 4. Atajos de Teclado (sxhkd)

### Aplicaciones

| Atajo | Accion |
|-------|--------|
| `Super + Return` | Kitty (terminal) |
| `Super + d` | Rofi (launcher) |
| `Super + Shift + f` | Firefox |
| `Super + Shift + g` | Google Chrome |
| `Super + Shift + o` | Tor Browser |
| `Super + Shift + x` | i3lock-fancy (bloqueo) |
| `Super + Shift + p` | Flameshot (captura) |
| `Super + p` | Flameshot (captura) |
| `Print` | Flameshot (captura) |

### Ventanas

| Atajo | Accion |
|-------|--------|
| `Super + q` | Cerrar ventana |
| `Super + m` | Toggle monocle layout |
| `Super + t` | Tiled |
| `Super + Shift + t` | Pseudo-tiled |
| `Super + s` | Floating |
| `Super + f` | Fullscreen |
| `Super + Flechas` | Mover foco |
| `Super + Shift + Flechas` | Mover ventana |
| `Super + Alt + Flechas` | Redimensionar ventana |
| `Super + {1-9,0}` | Ir a escritorio 1-10 |
| `Super + Shift + {1-9,0}` | Enviar ventana a escritorio |

### Sistema

| Atajo | Accion |
|-------|--------|
| `Super + Escape` | Recargar sxhkd |
| `Super + Alt + q` | Salir de bspwm |
| `Super + Alt + r` | Reiniciar bspwm |
| `Super + Tab` | Ultimo escritorio |
| `` Super + ` `` | Ultimo nodo |

---

## 5. Scripts de Servicios (TUI interactivas)

### startftp
- Iniciar FTP rapido (anonimo, puerto 2121)
- Iniciar personalizado (usuario + password + puerto)
- Conectar a FTP remoto
- Detener servidor / Ver logs / Estado

### startssh
- Activar/Detener servicio SSH
- Conectar a host remoto
- Gestionar perfiles guardados (agregar/eliminar)
- Generar llaves SSH (ed25519)
- Copiar llave a host remoto

### startfire
- Activar/Detener firewall
- Ver estado y reglas
- Permitir/Bloquear puertos (TCP/UDP)
- Denegar IP completa o por puerto
- Eliminar reglas individuales
- Reset completo
- Escaneo de puertos locales en LISTEN

### compartidos
- Creacion recomendada (asistida, 1 paso + test automatico)
- Crear compartido manual (autenticado o guest)
- Crear/Editar/Eliminar usuarios Samba
- Gestion: agregar usuario, toggle lectura/guest
- Ver estado, conexiones activas
- Diagnostico y test de conectividad

---

## 6. Scripts de Polybar (bspwm)

| Script | Funcion |
|--------|---------|
| `ethernet.sh` | Detecta IP ethernet dinamicamente |
| `wifi.sh` | Detecta IP WiFi dinamicamente |
| `vpn.sh` | Muestra IP de tun0 (VPN activa) |
| `target.sh` | Muestra target actual (settarget) |
| `infbat.sh` | Bateria + fecha/hora |
| `bspwm_resize` | Redimensionado personalizado de ventanas |

---

## 7. Scripts de WiFi/Red

| Script | Funcion |
|--------|---------|
| `wifi_conect.py` | Menu Python: escanear, conectar, desconectar WiFi |
| `tlwn722n-monitormode.sh` | Modo monitor TL-WN722N (compilar driver, airodump) |
| `restar_Ser.sh` | Restaurar NetworkManager + wpa_supplicant |

---

## 8. Variables de Entorno

| Variable | Valor |
|----------|-------|
| `_JAVA_AWT_WM_NONREPARENTING` | 1 (fix Java en bspwm) |
| `HISTSIZE` | 10000 |
| `SAVEHIST` | 10000 |
| `MOSKOV_BASE` | `~/Desktop/usuario` |
| `CIBER_BASE` | `~/Desktop/usuario/Ciberseguridad` |
