#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
crear_pass_smtp.py
Crea de forma segura un archivo pass_smtp con formato:
[smtp.host.com]:puerto<TAB>usuario:contraseña
Se escribe en UTF-8, carpeta 700 y archivo 600.
"""

import os
import sys
import getpass
import tempfile
import shutil

DEFAULT_HOST = "[smtp.gmail.com]:587"
DEFAULT_BASE_DIR = os.path.expanduser("~/Desktop/" + os.getlogin() + "/Ciberseguridad/Local_Services/SMTP/pass")
DEFAULT_FILENAME = "pass_smtp"


def ask(prompt, default=None):
    if default:
        v = input(f"{prompt} [Enter para '{default}']: ").strip()
        return v if v else default
    return input(prompt).strip()


def simple_email_ok(email: str) -> bool:
    return "@" in email and "." in email and len(email) > 5


def main():
    print("=== Crear pass_smtp seguro (Python) ===")

    host = ask("Host SMTP (formato [host]:puerto)", DEFAULT_HOST)

    # pedir usuario (correo) validando mínimamente
    while True:
        user = input("Usuario (correo SMTP): ").strip()
        if not user:
            print("El correo no puede estar vacío.")
            continue
        if not simple_email_ok(user):
            print("Formato de correo aparentemente inválido. Intenta de nuevo.")
            continue
        break

    # pedir contraseña en modo oculto
    while True:
        passwd = getpass.getpass("Contraseña de aplicación (no se mostrará): ").strip()
        if not passwd:
            print("La contraseña no puede estar vacía.")
            continue
        break

    base_dir = ask("Ruta donde guardar archivo", DEFAULT_BASE_DIR)
    filename = ask("Nombre del archivo (solo nombre)", DEFAULT_FILENAME)

    # normalizar ruta
    base_dir = os.path.expanduser(base_dir)
    dest_path = os.path.join(base_dir, filename)

    print("\nResumen:")
    print("  Host:   ", host)
    print("  Usuario:", user)
    print("  Destino:", dest_path)
    confirm = input("¿Confirmas la creación del archivo en esa ruta? (s/n): ").strip().lower()
    if confirm not in ("s", "si", "y", "yes"):
        print("Operación cancelada.")
        sys.exit(0)

    # crear directorio si no existe y aplicar permisos 700
    try:
        os.makedirs(base_dir, exist_ok=True)
    except Exception as e:
        print(f"Error creando directorio {base_dir}: {e}")
        sys.exit(1)

    try:
        # aplicar permisos 700 al directorio (seguro)
        os.chmod(base_dir, 0o700)
    except Exception as e:
        print(f"Advertencia: no se pudo fijar permisos 700 en {base_dir}: {e}")

    # escribir en archivo temporal en el mismo directorio (atomic move)
    fd = None
    tmp_path = None
    try:
        fd, tmp_path = tempfile.mkstemp(prefix=".tmp_pass_", dir=base_dir, text=True)
        os.close(fd)
        # establecer umask para que el archivo temporal sea creado con permisos restrictivos
        old_umask = os.umask(0o177)
        try:
            with open(tmp_path, "w", encoding="utf-8", newline="\n") as f:
                # formato exacto que espera Postfix: host<TAB>user:pass
                f.write(f"{host}\t{user}:{passwd}\n")
        finally:
            os.umask(old_umask)

        # mover atómicamente al destino
        shutil.move(tmp_path, dest_path)
        tmp_path = None

        # aplicar permisos 600 al archivo final
        os.chmod(dest_path, 0o600)

        # si estamos corriendo como root, fijar propietario a root:root
        if os.geteuid() == 0:
            try:
                import pwd, grp
                uid = pwd.getpwnam("root").pw_uid
                gid = grp.getgrnam("root").gr_gid
                os.chown(dest_path, uid, gid)
            except Exception as e:
                print(f"Advertencia: no se pudo cambiar propietario a root: {e}")

        print("\nArchivo creado correctamente:")
        print("  ", dest_path)
        print("Permisos (modo):", oct(os.stat(dest_path).st_mode & 0o777))
        print("Nota: la contraseña no fue mostrada ni guardada en logs por este script.")
    except Exception as e:
        print(f"Error al crear el archivo: {e}")
        # intentar limpiar temporal si existe
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrumpido por usuario.")
        sys.exit(1)
