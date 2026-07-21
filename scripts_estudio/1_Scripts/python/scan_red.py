#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scan_red.py - Scanner de red local con deteccion de hosts activos
Autor: Moskov
Descripcion: Escanea la red local usando nmap, detecta hosts activos,
             recopila info de red y exporta todo a un archivo de texto.
Dependencias: nmap (instalado en el sistema)
Uso: sudo python3 scan_red.py
"""

import os
import sys
import subprocess
from datetime import datetime


# Colores para terminal
GREEN = "\033[0;32m"
RED = "\033[0;31m"
CYAN = "\033[0;36m"
RESET = "\033[0m"


def verificar_root():
    """Verifica que el script se ejecute como root."""
    if os.geteuid() != 0:
        print(f"{RED}  [!] Este script requiere permisos root.{RESET}")
        print(f"      Ejecuta: sudo python3 {sys.argv[0]}")
        sys.exit(1)


def obtener_info_red():
    """Obtiene la informacion de red del sistema."""
    info = {}
    try:
        info['ip'] = subprocess.check_output(["hostname", "-I"]).decode().strip().split()[0]
        
        # Obtener gateway y subred
        route_output = subprocess.check_output(["ip", "route"]).decode()
        for line in route_output.splitlines():
            if line.startswith("default"):
                info['gateway'] = line.split()[2]
            elif info.get('ip') and info['ip'].rsplit('.', 1)[0] in line:
                info['subred'] = line.split()[0]

        # MAC address
        ip_link = subprocess.check_output(["ip", "link"]).decode()
        for line in ip_link.splitlines():
            if "link/ether" in line:
                info['mac'] = line.strip().split()[1]
                break

    except (subprocess.CalledProcessError, IndexError) as e:
        print(f"{RED}  [!] Error obteniendo info de red: {e}{RESET}")

    return info


def escanear_red(subred):
    """Escanea la red local con nmap y devuelve hosts activos."""
    print(f"{CYAN}  [*] Escaneando red: {subred}{RESET}")
    print(f"      Esto puede tardar unos segundos...\n")

    try:
        output = subprocess.check_output(
            ["nmap", "-T4", "-sn", subred],
            stderr=subprocess.DEVNULL
        ).decode()

        hosts = []
        for line in output.splitlines():
            if "Nmap scan report for" in line:
                parts = line.split()
                # Puede ser "host (IP)" o solo "IP"
                if "(" in line:
                    hostname = parts[4]
                    ip = parts[5].strip("()")
                else:
                    hostname = ""
                    ip = parts[4]
                hosts.append({'ip': ip, 'hostname': hostname})

        return hosts

    except FileNotFoundError:
        print(f"{RED}  [!] nmap no esta instalado. Instala con: sudo apt install nmap{RESET}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"{RED}  [!] Error en el escaneo: {e}{RESET}")
        return []


def exportar_resultados(info_red, hosts, filename):
    """Exporta los resultados a un archivo de texto."""
    with open(filename, "w") as f:
        f.write(f"{'='*60}\n")
        f.write(f"  ESCANEO DE RED LOCAL - {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}\n")
        f.write(f"{'='*60}\n\n")

        f.write("  INFORMACION DE RED:\n")
        f.write(f"  {'─'*40}\n")
        f.write(f"  IP Local:      {info_red.get('ip', 'N/A')}\n")
        f.write(f"  MAC:           {info_red.get('mac', 'N/A')}\n")
        f.write(f"  Gateway:       {info_red.get('gateway', 'N/A')}\n")
        f.write(f"  Subred:        {info_red.get('subred', 'N/A')}\n\n")

        f.write(f"  HOSTS ACTIVOS: {len(hosts)}\n")
        f.write(f"  {'─'*40}\n")
        for i, host in enumerate(hosts, 1):
            hostname = f" ({host['hostname']})" if host['hostname'] else ""
            f.write(f"  {i:3d}. {host['ip']}{hostname}\n")

        f.write(f"\n{'='*60}\n")

    return filename


def main():
    print(f"\n{GREEN}  ============================{RESET}")
    print(f"{GREEN}   Scanner de Red Local{RESET}")
    print(f"{GREEN}  ============================{RESET}\n")

    verificar_root()

    # Obtener info de red
    info_red = obtener_info_red()
    print(f"{GREEN}  [+] IP Local:  {info_red.get('ip', 'N/A')}{RESET}")
    print(f"{GREEN}  [+] Gateway:   {info_red.get('gateway', 'N/A')}{RESET}")
    print(f"{GREEN}  [+] Subred:    {info_red.get('subred', 'N/A')}{RESET}\n")

    # Determinar subred a escanear
    subred = info_red.get('subred')
    if not subred:
        subred = input("  Introduce la subred a escanear (ej: 192.168.1.0/24): ").strip()

    # Escanear
    hosts = escanear_red(subred)

    if hosts:
        print(f"{GREEN}  [+] Hosts activos encontrados: {len(hosts)}{RESET}\n")
        for i, host in enumerate(hosts, 1):
            hostname = f" ({host['hostname']})" if host['hostname'] else ""
            print(f"      {i:3d}. {host['ip']}{hostname}")

        # Exportar
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"escaneo_red_{timestamp}.txt"
        exportar_resultados(info_red, hosts, filename)
        print(f"\n{GREEN}  [+] Resultados exportados a: {filename}{RESET}\n")
    else:
        print(f"{RED}  [!] No se encontraron hosts activos.{RESET}\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{RED}  [!] Escaneo cancelado.{RESET}\n")
        sys.exit(0)
