# Guia de Instalacion

Script 100% portatil y dinamico. Compatible con cualquier usuario del sistema.

---

## Requisitos

- Parrot Security 6.x o Debian 12+ (cualquier instalacion)
- Conexion a internet
- Git: `apt install git`

---

## Instalacion (un solo comando)

```bash
git clone https://github.com/ThinMoskov25/Entorno_LinuxParrot.git ~/dotfiles
cd ~/dotfiles
sudo bash install_environment.sh
```

El script:
- Detecta automaticamente el usuario que ejecuto sudo (sin hardcoding)
- Funciona para cualquier nombre de usuario (moskov, admin, user1, etc.)
- Solicita contrasena una sola vez al inicio
- Presenta menu interactivo con 3 opciones

---

## Menu del Instalador

```
  1) Instalacion Limpia desde 0 (Destructiva/Completa)
  2) Reinstalar / Restaurar Entorno (Sobrescribir dotfiles)
  3) Actualizar solo Scripts de Servicios
  0) Salir
```

---

## Opcion 1: Instalacion Destructiva

Proceso automatico en 7 fases. Solo requiere 2 confirmaciones (inicio + pre-limpieza).

### Pre-limpieza (con autorizacion)

Si se detectan carpetas de un despliegue anterior, el script pregunta:

```
Se detectaron carpetas de un entorno anterior.
Eliminar completamente la estructura previa? (s/n):
```

- **s**: Borra todo y comienza desde cero
- **n**: Mantiene lo existente, instala encima

### Fases de ejecucion

| Fase | Accion |
|------|--------|
| 1/7 | Enmascarar servicios de red + kill procesos graficos + purga KDE/SDDM/GDM |
| 2/7 | apt --reinstall forzado (50+ paquetes) + LightDM sin prompts |
| 3/7 | bspwm-session + bspwm.desktop + xinitrc + mask SDDM + enable LightDM |
| 4/7 | Reinstalar Kitty, Neovim, Powerlevel10k, fzf (sobreescritura forzada) |
| 5/7 | Crear estructura + copiar scripts y configs desde el repo |
| 6/7 | chmod +x + Nerd Fonts + chown dinamico al usuario detectado |
| 7/7 | Shell zsh + UFW + comando update + restart LightDM |

---

## Opcion 2: Reinstalar Configuracion

- Sobrescribe ~/.config/ y scripts
- Aplica permisos y propiedad
- No reinstala paquetes ni binarios

---

## Opcion 3: Actualizar Scripts

Solo copia los scripts de servicios desde el repo:
- gestionar_compartidos.sh, startfire.sh, startssh.sh, startftp.sh, open_ftp.sh

---

## Portabilidad

El script NO contiene rutas estaticas ni nombres de usuario hardcodeados. Detecta:

| Variable | Como se obtiene |
|----------|-----------------|
| TARGET_USER | `$SUDO_USER` -> `logname` -> `who` |
| TARGET_HOME | `getent passwd $TARGET_USER` (campo 6) |
| REPO_DIR | Directorio donde reside el script |

Esto permite que funcione en cualquier maquina con cualquier usuario.

---

## Post-Instalacion

```bash
sudo reboot
```

LightDM arranca automaticamente con BSPWM. No requiere seleccion manual.

---

## Problemas Frecuentes

| Problema | Solucion |
|----------|----------|
| apt se congela | Script enmascara isc-dhcp-server automaticamente |
| Prompt interactivo Debian | DEBIAN_FRONTEND=noninteractive + force-conf |
| BSPWM no en login | Ejecutar opcion 1 (crea .desktop + bspwm-session) |
| Pantalla negra | Permisos de bspwmrc (se corrigen en fase 6) |
| Carpetas vacias | Copia recursiva real desde REPO_DIR (fase 5) |
| Rebote en login (files owned by root) | chown -R $TARGET_USER:$TARGET_USER $HOME (fase 6) |

---

## Actualizar

```bash
cd ~/dotfiles && git pull origin main
sudo bash install_environment.sh
# Opcion 2 o 3
```
