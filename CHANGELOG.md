# Changelog - Moskov Environment

---

## v3.0 Final (2026-08-02)

### Arquitectura Zero-Intervention
- Instalacion 100% desatendida con `--auto`
- Pre-flight automatico: limpieza APT/DPKG antes de instalar
- Deteccion de sesion grafica activa (no destruye X11)
- Aislamiento modular: fallos APT no bloquean dotfiles
- Deteccion dinamica de usuario (6 metodos de fallback)

### Funcionalidades Nuevas
- `post_config.sh` — Menu TUI post-instalacion
- `update` command — Snapshot timeshift + parrot-upgrade
- Scripts de red dinamicos (ethernet.sh, wifi.sh sin hardcodeo)
- P10k automatico para root
- Autocompletado case-insensitive en root

### Scripts de Servicios
- `gestionar_compartidos.sh` — Gestor Samba v6.0
- `startfire.sh` — Gestor Firewall UFW
- `startftp.sh` — Gestor FTP (pyftpdlib)
- `startssh.sh` — Gestor SSH completo

### Correcciones
- bspwm-session: PATH completo + deteccion dinamica de binarios
- neofetch removido (no existe en Parrot 13) → fastfetch
- picom: backend xrender (sin GPU requerida), blur desactivado
- Polybar: interface-type wired/wireless (deteccion automatica)
- zshrc: glob /opt fix con find (no rompe p10k)
- bat/batcat: alias condicional segun distribucion
- Rutas: todas dinamicas con nombre de usuario real
- Fork bomb: eliminados symlinks en ~/.local/bin que causaban recursion infinita con sudo
- Scripts de servicios accesibles SOLO via aliases en .zshrc (sin duplicacion en PATH)

---

## v2.0 (2026-07-18)

### Mejoras
- Instalador modular por fases
- Soporte para modo interactivo y automatico
- Compilacion de bspwm/sxhkd desde fuente (removido en v3)

---

## v1.0 (2025-09-28)

### Release Inicial
- Configuracion basica bspwm + polybar + kitty
- Scripts de pentesting
- Instalacion manual paso a paso
