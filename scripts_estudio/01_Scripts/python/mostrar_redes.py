#!/usr/bin/env python3

import subprocess

def mostrar_redes_disponibles():
    try:
        subprocess.run(["nmcli", "device", "wifi", "list"], check=True)
    except KeyboardInterrupt:
        print("\n¡Operación interrumpida! Cerrando...")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    mostrar_redes_disponibles()
