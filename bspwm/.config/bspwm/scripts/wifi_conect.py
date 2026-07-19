#!/usr/bin/env python3

import subprocess
import getpass
import signal
import sys
import datetime
import threading
import time
import os

# Colores
AZUL = "\033[94m"
CIAN = "\033[96m"
VERDE = "\033[92m"
AMARILLO = "\033[93m"
ROJO = "\033[91m"
NEGRITA = "\033[1m"
RESET = "\033[0m"

# Forzar colores (si se activa)
FORZAR_COLORES = True  # Establecer como True para activar colores, False para desactivarlos

# Ctrl+C
def salir_gracioso(sig, frame):
    print(f"\n{AMARILLO}👋 Hasta luego...{RESET}")
    sys.exit(0)

signal.signal(signal.SIGINT, salir_gracioso)

# Registrar errores y eliminarlos después de 5 minutos
def registrar_error_log(error):
    log_file_path = "wifi_error.log"
    fecha = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file_path, "a") as log_file:
        log_file.write(f"[{fecha}] {error}\n")

    # Hilo para eliminar el log tras 5 minutos
    def eliminar_log():
        time.sleep(300)
        if os.path.exists(log_file_path):
            try:
                os.remove(log_file_path)
            except Exception:
                pass

    threading.Thread(target=eliminar_log, daemon=True).start()

# Registrar la conexión exitosa en el log
def registrar_conexion_exitosa(ssid):
    log_file_path = "wifi_error.log"
    fecha = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file_path, "a") as log_file:
        log_file.write(f"[{fecha}] Conexión exitosa a la red: {ssid}\n")

    # Hilo para eliminar el log tras 5 minutos
    def eliminar_log():
        time.sleep(300)
        if os.path.exists(log_file_path):
            try:
                os.remove(log_file_path)
            except Exception:
                pass

    threading.Thread(target=eliminar_log, daemon=True).start()

# Mostrar redes disponibles
def mostrar_redes():
    try:
        print(f"{CIAN}🔍 Escaneando redes...{RESET}")
        subprocess.run(["nmcli", "device", "wifi", "rescan"], check=True)
        time.sleep(2)  # Esperar un poco para asegurar que la red se escanea

        # Si FORZAR_COLORES está activado, usamos nmcli con colores
        if FORZAR_COLORES:
            resultado = subprocess.run(
                ["nmcli", "--colors", "yes", "device", "wifi", "list"],
                capture_output=True, text=True, check=True
            )
        else:
            resultado = subprocess.run(
                ["nmcli", "device", "wifi", "list"],
                capture_output=True, text=True, check=True
            )
        
        print(f"\n{AZUL}{NEGRITA}📶 Redes WiFi Disponibles:{RESET}")
        print(resultado.stdout)
    except subprocess.CalledProcessError as e:
        print(f"{ROJO}❌ Error al obtener redes WiFi{RESET}")
        registrar_error_log(str(e))
        return False
    return True

# Conectar a una red WiFi
def conectar_por_ssid():
    try:
        ssid = input(f"{NEGRITA}📡 Ingresa el SSID exacto de la red a conectar: {RESET}").strip()
        password = getpass.getpass("🔑 Ingresa la contraseña: ")

        print(f"{CIAN}🔗 Intentando conectar a la red: {ssid}{RESET}")
        
        # Aquí eliminamos la línea que muestra el comando con la contraseña
        resultado = subprocess.run(
            ["nmcli", "dev", "wifi", "connect", ssid, "password", password],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"{VERDE}✅ Conectado correctamente a '{ssid}'{RESET}")
        
        # Registrar en el log que la conexión fue exitosa
        registrar_conexion_exitosa(ssid)
        
    except subprocess.CalledProcessError as e:
        print(f"{ROJO}❌ No se pudo conectar a la red. Error: {e.stderr}{RESET}")
        registrar_error_log(e.stderr.strip())

# Desconectar red actual
def desconectar_red():
    try:
        interfaz = subprocess.check_output(["nmcli", "-t", "-f", "DEVICE,TYPE", "device"], text=True)
        for linea in interfaz.strip().splitlines():
            disp, tipo = linea.split(":")
            if tipo == "wifi":
                subprocess.run(["nmcli", "device", "disconnect", disp], check=True)
                print(f"{AMARILLO}🔌 Desconectado de la red WiFi.{RESET}")
                return
        print(f"{AMARILLO}❌ No se encontró interfaz WiFi activa.{RESET}")
    except Exception as e:
        print(f"{ROJO}❌ Error al desconectar: {e}{RESET}")
        registrar_error_log(str(e))

# Menú principal
def mostrar_menu():
    print(f"\n{AZUL}{NEGRITA}*** Menú de Opciones ***{RESET}")
    print(f"{VERDE}1 - Mostrar redes disponibles y conectar")
    print(f"2 - Conectar a una red WiFi manualmente (por SSID)")
    print(f"3 - Desconectar de la red WiFi")
    print(f"4 - Salir{RESET}")

def main():
    while True:
        mostrar_menu()
        opcion = input(f"{NEGRITA}\nSelecciona una opción (1/2/3/4): {RESET}").strip()
        if opcion == "1":
            if mostrar_redes():
                conectar_por_ssid()
        elif opcion == "2":
            conectar_por_ssid()
        elif opcion == "3":
            desconectar_red()
        elif opcion == "4":
            print(f"{AMARILLO}👋 ¡Hasta luego!{RESET}")
            break
        else:
            print(f"{AMARILLO}❌ Opción no válida.{RESET}")

if __name__ == "__main__":
    main()
