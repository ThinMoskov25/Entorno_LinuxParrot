# Moskov Environment v3.0

Entorno de escritorio completo sobre Parrot Security OS / Debian 12+ con bspwm.
Instalacion 100% automatizada, desatendida y zero-intervention.

---

## Caracteristicas

- **WM:** bspwm + sxhkd (tiling window manager)
- **Barra:** Polybar (modular, scripts personalizados)
- **Terminal:** Kitty + zsh + Powerlevel10k
- **Editor:** Neovim (NvChad)
- **Compositor:** Picom (xrender, sin GPU requerida)
- **Launcher:** Rofi (20+ temas incluidos)
- **Lock:** i3lock-fancy
- **Capturas:** Flameshot
- **Red:** Scripts dinamicos ethernet/wifi/vpn en polybar
- **Seguridad:** Metasploit, nmap, hydra, hashcat, sqlmap, wireshark, impacket, evil-winrm, wpscan

---

## Instalacion Rapida

```bash
sudo parrot-upgrade && sudo apt install -y git && \
git clone https://github.com/ThinMoskov25/Entorno_LinuxParrot.git /tmp/entorno && \
sudo bash /tmp/entorno/install_environment.sh --auto
```

Ver [INSTALLATION.md](INSTALLATION.md) para opciones avanzadas.

---

## Estructura del Repositorio

```
├── Apps/                     Scripts de instalacion de aplicaciones
├── bspwm/                    Window Manager (bspwmrc + scripts polybar)
├── sxhkd/                    Atajos de teclado globales
├── polybar/                  Barra de estado (config, colores, fuentes, scripts)
├── picom/                    Compositor de ventanas
├── kitty/                    Emulador de terminal
├── rofi/                     Lanzador de aplicaciones (config + temas)
├── nvim/                     Neovim (NvChad - LSP, plugins)
├── neofetch/                 Info del sistema
├── zsh/                      .p10k.zsh (Powerlevel10k theme)
├── bash/                     .bashrc + .profile
├── scripts_estudio/          Scripts de ciberseguridad y servicios
├── wallpaper/                Fondo de pantalla
├── install_environment.sh    Instalador principal
├── post_config.sh            Configuracion post-instalacion (TUI)
├── zshrc                     Configuracion de zsh (se despliega como ~/.zshrc)
├── INSTALLATION.md           Guia de instalacion
├── FUNCIONES.md              Referencia de funciones y comandos
├── NVIM.md                   Guia de uso de Neovim
├── REPOS.md                  Repositorios externos utilizados
└── CHANGELOG.md              Historial de versiones
```

---

## Post-Instalacion

Despues del reboot, ejecutar:

```bash
bash ~/Desktop/$(whoami)/post_config.sh
```

Opciones disponibles:
1. Configurar Powerlevel10k
2. Instalar Apps
3. Configurar Red
4. Validar Scripts
5. Ver funciones y comandos disponibles

---

## Documentacion

| Documento | Contenido |
|-----------|-----------|
| [INSTALLATION.md](INSTALLATION.md) | Guia de instalacion paso a paso |
| [FUNCIONES.md](FUNCIONES.md) | Funciones, aliases y atajos de teclado |
| [NVIM.md](NVIM.md) | Guia de Neovim con NvChad |
| [REPOS.md](REPOS.md) | Repositorios y fuentes externas |
| [CHANGELOG.md](CHANGELOG.md) | Historial de cambios |

---

## Autor

**Moskov - SrBalduR**

Licencia: Uso personal y educativo.
