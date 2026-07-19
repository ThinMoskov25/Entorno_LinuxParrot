# coding: utf-8
import re
import sys
import subprocess
from platform import system
from termcolor import colored

def get_ttl(ip_address):
    try:
        param = "-n" if system().lower() == "windows" else "-c"
        result = subprocess.run(
            ["ping", param, "1", ip_address],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=3
        )

        if result.returncode != 0:
            print(colored("[!] Error al hacer ping a la IP", "red"))
            sys.exit(1)

        ttl_match = re.search(r"ttl[=|:](\d+)", result.stdout, re.IGNORECASE)
        if ttl_match:
            return int(ttl_match.group(1))
        else:
            print(colored("[!] No se pudo obtener el TTL", "red"))
            sys.exit(1)

    except Exception as e:
        print(colored(f"[!] Error: {str(e)}", "red"))
        sys.exit(1)

def get_os(ttl):
    if ttl <= 64:
        return "Linux"
    elif 65 <= ttl <= 128:
        return "Windows"
    else:
        return "Desconocido"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Uso: python3 {sys.argv[0]} <IP>")
        sys.exit(1)

    ip_address = sys.argv[1]
    ttl = get_ttl(ip_address)
    os_name = get_os(ttl)

    print(
        colored(f"[+] {ip_address} (ttl -> {ttl}): ", "yellow") +
        colored(f"{os_name}", "blue")
    )
