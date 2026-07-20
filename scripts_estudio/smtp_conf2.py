import os
import smtplib
import subprocess
from datetime import datetime
from getpass import getpass

# --- Configuración de rutas ---
BASE_DIR = "/home/moskov/Desktop/Moskov/Ciberseguridad/Local_Services/SMTP"
LOG_DIR = os.path.join(BASE_DIR, "logs")
PASS_DIR = os.path.join(BASE_DIR, "pass")
PASS_FILE = os.path.join(PASS_DIR, "gmail_app_pass.txt")
GMAIL_ACCOUNT = "thinmoskov@gmail.com"

# Crear carpetas con permisos seguros
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(PASS_DIR, mode=0o700, exist_ok=True)

def log_message(message):
    timestamp = datetime.now().strftime("%d-%m-%H-%M")
    log_file = os.path.join(LOG_DIR, f"smtp_log_{timestamp}.log")
    with open(log_file, "a") as f:
        f.write(f"{datetime.now()}: {message}\n")
    print(message)

# --- Verificar Postfix ---
def check_postfix():
    try:
        status = subprocess.check_output(["systemctl", "is-active", "postfix"], text=True).strip()
        if status == "active":
            log_message("Postfix está activo.")
            return True
        else:
            log_message("Postfix NO está activo.")
            return False
    except Exception as e:
        log_message(f"Error verificando Postfix: {e}")
        return False

# --- Función para enviar correo ---
def send_email(to, subject, body, use_gmail=False, gmail_pass=None):
    try:
        now = datetime.now().strftime("%d:%m:%Y - %H:%M")
        body += f"\n\nCorreo Recibido por SMTP {now}"

        if use_gmail:
            server = smtplib.SMTP("smtp.gmail.com", 587)
            server.starttls()
            server.login(GMAIL_ACCOUNT, gmail_pass)
            sender = GMAIL_ACCOUNT
        else:
            server = smtplib.SMTP("localhost", 25)
            sender = "root@localhost"

        full_message = f"Subject: {subject}\n\n{body}"
        server.sendmail(sender, to, full_message)
        server.quit()
        log_message(f"Correo enviado a {to} con éxito.")
    except Exception as e:
        log_message(f"Error al enviar correo a {to}: {e}")

# --- Configurar Gmail de manera segura ---
def configure_gmail():
    # Intentar leer archivo seguro
    if os.path.exists(PASS_FILE):
        try:
            with open(PASS_FILE, "r") as f:
                gmail_pass = f.read().strip()
            return gmail_pass
        except Exception as e:
            log_message(f"No se pudo leer archivo de clave: {e}")

    # Si no existe, pedir al usuario y crear archivo seguro
    gmail_pass = getpass(f"Ingresa clave de aplicación para {GMAIL_ACCOUNT}: ").strip()
    try:
        with open(PASS_FILE, "w") as f:
            f.write(gmail_pass)
        os.chmod(PASS_FILE, 0o600)  # Solo lectura/escritura para usuario
        log_message("Clave de Gmail guardada de manera segura.")
    except Exception as e:
        log_message(f"No se pudo guardar la clave: {e}")
    return gmail_pass

# --- Menú interactivo ---
def main_menu():
    while True:
        print("\n=== Menú SMTP Interactivo ===")
        print("1) Verificar servicio Postfix")
        print("2) Enviar correo local")
        print("3) Enviar correo Gmail")
        print("4) Salir")
        choice = input("Selecciona una opción: ").strip()

        if choice == "1":
            check_postfix()
        elif choice == "2":
            if check_postfix():
                to = input("Destinatario: ").strip()
                subject = input("Asunto: ").strip()
                body = input("Mensaje: ").strip()
                send_email(to, subject, body, use_gmail=False)
            else:
                log_message("No se puede enviar correo local: Postfix no activo.")
        elif choice == "3":
            gmail_pass = configure_gmail()
            if gmail_pass:
                to = input("Destinatario: ").strip()
                subject = input("Asunto: ").strip()
                body = input("Mensaje: ").strip()
                send_email(to, subject, body, use_gmail=True, gmail_pass=gmail_pass)
        elif choice == "4":
            log_message("Saliendo del programa.")
            break
        else:
            log_message("Opción inválida, intenta de nuevo.")

if __name__ == "__main__":
    main_menu()
