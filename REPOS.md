# Repositorios y Fuentes Externas - Moskov Environment v3.0

---

## Herramientas Compiladas / Descargadas

| Herramienta | Fuente | Destino |
|-------------|--------|---------|
| Kitty | https://sw.kovidgoyal.net/kitty/installer.sh | /opt/kitty/ |
| Neovim | https://github.com/neovim/neovim/releases | /opt/nvim/ |
| Powerlevel10k | https://github.com/romkatv/powerlevel10k | ~/powerlevel10k/ |
| fzf | https://github.com/junegunn/fzf | ~/.fzf/ |
| i3lock-fancy | https://github.com/meskarune/i3lock-fancy | /opt/i3lock-fancy/ |
| Rofi themes | https://github.com/newmanls/rofi-themes-collection | /opt/rofi-themes-collection/ |
| Impacket | https://github.com/fortra/impacket | /opt/impacket/ |
| pspy | https://github.com/DominicBreuker/pspy/releases | /opt/pspy/ |
| ngrok | https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | /opt/ngrok/ |

---

## Repositorios de Configuracion

| Componente | Repositorio base |
|------------|-----------------|
| NvChad | https://github.com/NvChad/NvChad |
| lazy.nvim | https://github.com/folke/lazy.nvim |
| nvim-lspconfig | https://github.com/neovim/nvim-lspconfig |
| conform.nvim | https://github.com/stevearc/conform.nvim |

---

## Paquetes APT Principales

### Entorno Grafico
```
bspwm sxhkd polybar picom rofi feh maim xclip xdotool xdo wmname
i3lock flameshot imagemagick xorg xserver-xorg-core xinit
lightdm lightdm-gtk-greeter x11-xserver-utils
```

### Shell y Terminal
```
zsh zsh-autosuggestions zsh-syntax-highlighting fzf bat
tmux ranger htop iftop nload
```

### Desarrollo
```
git curl wget stow build-essential golang-go nodejs npm
python3 python3-pip python3-dev default-jdk ruby ruby-dev
cmake meson ninja-build nasm
libncurses-dev libreadline-dev libssl-dev libsqlite3-dev
libpcap-dev libconfig-dev libev-dev libx11-xcb-dev
libxcb1-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-randr0-dev
libxcb-util-dev libxcb-keysyms1-dev libxcb-shape0-dev
pkg-config autoconf libtool
```

### Redes y Servicios
```
net-tools nmap masscan netdiscover traceroute
samba nfs-common nfs-kernel-server sshfs cifs-utils
ufw gufw socat proxychains sshpass
network-manager network-manager-openvpn
postfix postgresql sqlite3
```

### Pentesting / Seguridad
```
aircrack-ng bettercap binwalk cewl commix crunch
dmitry dnsenum enum4linux fcrackzip gobuster hashcat hashid
hping3 hydra john joomscan macchanger mdk4 nikto nishang
onesixtyone smbmap smtp-user-enum sqlmap tshark websploit
wfuzz whois wireshark metasploit-framework
```

### Utilidades
```
unzip zip rsync p7zip-full fonts-font-awesome brightnessctl
pamixer timeshift gparted remmina vim flatpak torbrowser-launcher
lsd fastfetch
```

---

## Gems (Ruby)

| Gem | Funcion |
|-----|---------|
| evil-winrm | Shell remota Windows via WinRM |
| wpscan | Scanner de vulnerabilidades WordPress |

---

## Pip (Python)

| Paquete | Funcion |
|---------|---------|
| impacket | Herramientas de red (SMB, NTLM, Kerberos) |
| pyftpdlib | Servidor FTP en Python (usado por startftp) |

---

## Fuentes Tipograficas

| Fuente | Uso |
|--------|-----|
| Hack Nerd Font | Terminal / Polybar |
| FiraCode | Editor |
| Font Awesome | Iconos en polybar |
| Helvetica | Polybar temas |
| Iosevka Nerd Font | Alternativa polybar |
| feather.ttf | Iconos adicionales |

---

## Repositorio Principal

```
https://github.com/ThinMoskov25/Entorno_LinuxParrot.git
```
