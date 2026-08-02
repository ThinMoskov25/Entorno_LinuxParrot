# Registro de Actualizaciones

---

## v3.0 (2026-07-21)

### Nuevos Scripts
- `gestionar_compartidos.sh` — Gestor completo de unidades compartidas SMB/NFS/SSHFS
- `startfire.sh` — Gestor interactivo de Firewall UFW

### Nuevas Funcionalidades
- Modo de acceso predeterminado seguro (cualquier usuario autenticado, lectura/escritura con proteccion de grupo)
- Edicion de compartidos existentes (permisos, usuarios, masks, ruta, modo)
- Eliminacion completa de compartidos (share + carpeta + usuario temporal + reinicio de servicio)
- Opcion 4 muestra compartidos Samba configurados, exportaciones NFS y montajes activos
- Filtrado de shares internos (print$) en el listado
- Escaneo de puertos locales en escucha (ss) en startfire

### Correcciones
- Estructura de carpetas sin ceros a la izquierda (01_Scripts -> 1_Scripts, 04_Servicios -> 4_Servicios)
- Rutas sin espacios (Conexiones Servicios -> Conexiones_Servicios)
- Variable mpoints declarada en alcance correcto para desmontar todas
- Filtro de print$ con comillas simples para escapar el $

### Actualizaciones
- startftp.sh, startssh.sh, open_ftp.sh usan la nueva ruta estandar Conexiones_Servicios
- .zshrc: aliases startfire, compartidos, funcion refresh()
- README.md reescrito como documentacion completa del proyecto

---

## v2.1 (2026-07-20)

### Cambios
- Sync: netaudit actualizado
- gestionar_compartidos.sh version inicial
- Powermenu ajustado a 260px
- Funciones netscan/compartidos agregadas en zshrc

---

## v2.0 (2026-07-20)

### Cambios
- Reorganizacion completa del repositorio
- Nueva estructura de carpetas 01-07
- Scripts corregidos y rutas actualizadas
- netaudit (Go) incluido
- README documentado por primera vez
- startftp.sh y startssh.sh agregados

---

## v1.0 (Inicial)

### Contenido
- Scripts de estudio (bash, python, go)
- Generadores de datos y passwords
- Configuraciones de bspwm, polybar, sxhkd, kitty, picom
