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
