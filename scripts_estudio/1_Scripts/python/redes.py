import time
import pyperclip
from rich.console import Console
from rich.prompt import Prompt
import subprocess

# Inicializa la consola para salida con texto enriquecido
console = Console()

# Función para restaurar servicios de red (por ejemplo, reiniciar el NetworkManager)
def restaurar_servicios_red():
    try:
        # Comando para reiniciar el servicio de red en Linux (puedes modificarlo si usas otro sistema)
        console.print("[yellow]Restaurando servicios de red...[/yellow]")
        subprocess.run(["sudo", "systemctl", "restart", "NetworkManager"], check=True)
        console.print("[green]Servicios de red restaurados con éxito.[/green]")
    except Exception as e:
        console.print(f"[red]Error al restaurar servicios de red: {e}[/red]")

# Función para obtener las interfaces de red disponibles
def obtener_interfaces_wifi():
    try:
        # Ejecuta el comando para obtener interfaces de red disponibles
        result = subprocess.run(
            ["nmcli", "device", "status"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        output = result.stdout
        interfaces = []

        # Analiza la salida y extrae las interfaces que son de tipo wifi
        for line in output.splitlines():
            if "wifi" in line and "unavailable" not in line:
                parts = line.split()
                interfaces.append(parts[0])  # Agrega el nombre de la interfaz

        return interfaces

    except Exception as e:
        console.print(f"[red]Error al obtener interfaces WiFi: {e}[/red]")
        return []

# Función para escanear redes WiFi usando `nmcli` (NetworkManager)
def scan_wifi(interface):
    try:
        # Ejecuta el comando `nmcli` para escanear redes WiFi en la interfaz seleccionada
        result = subprocess.run(
            ["nmcli", "-t", "-f", "BSSID,SIGNAL,CHAN,SECURITY,SSID", "dev", interface, "wifi"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        output = result.stdout
        networks = []

        # Analiza la salida y extrae la información relevante
        for line in output.splitlines():
            # Cada línea de la salida tiene estos datos: BSSID:SIGNAL:CHAN:SECURITY:SSID
            parts = line.split(":")
            if len(parts) == 5:
                network = {
                    'BSSID': parts[0],
                    'PWR': parts[1],
                    'CH': parts[2],
                    'ENC': parts[3],
                    'ESSID': parts[4]
                }
                networks.append(network)

        return networks

    except Exception as e:
        console.print(f"[red]Error al escanear redes WiFi: {e}[/red]")
        return []

# Función para mostrar la información de las redes WiFi y exportarla a un archivo de texto
def show_and_export_networks(networks, filename="redes_wifi.txt"):
    console.clear()
    
    with open(filename, "w") as f:
        if networks:
            for i, net in enumerate(networks):
                # Imprimir en la consola
                console.print(f"\nRed {i+1}:")
                console.print(f"BSSID: {net['BSSID']}")
                console.print(f"PWR: {net['PWR']} dBm")
                console.print(f"CH: {net['CH']}")
                console.print(f"ENC: {net['ENC']}")
                console.print(f"ESSID: {net['ESSID']}")
                console.print("-" * 40)
                
                # Escribir en el archivo
                f.write(f"\nRed {i+1}:\n")
                f.write(f"BSSID: {net['BSSID']}\n")
                f.write(f"PWR: {net['PWR']} dBm\n")
                f.write(f"CH: {net['CH']}\n")
                f.write(f"ENC: {net['ENC']}\n")
                f.write(f"ESSID: {net['ESSID']}\n")
                f.write("-" * 40 + "\n")
        else:
            console.print("[yellow]No se encontraron redes WiFi.[/yellow]")
            f.write("[yellow]No se encontraron redes WiFi.[/yellow]\n")

# Función principal para ejecutar el escaneo de redes WiFi y el ciclo de interacción
def main():
    restaurar_servicios_red()  # Llamamos a la función de restaurar servicios de red al inicio
    
    # Obtiene las interfaces WiFi disponibles
    interfaces = obtener_interfaces_wifi()
    
    if not interfaces:
        console.print("[red]No se encontraron interfaces WiFi disponibles.[/red]")
        return
    
    # Muestra las interfaces disponibles para que el usuario seleccione una
    console.print("[bold yellow]Interfaces WiFi disponibles:[/bold yellow]")
    for i, interfaz in enumerate(interfaces):
        console.print(f"[bold]{i + 1}. {interfaz}[/bold]")
    
    choice = Prompt.ask(
        "\n[bold yellow]Selecciona el número de la interfaz WiFi (q para salir):[/bold yellow]"
    )
    
    if choice.lower() == 'q':
        return
    
    # Verifica que la elección sea válida
    if choice.isdigit() and 0 < int(choice) <= len(interfaces):
        interfaz_seleccionada = interfaces[int(choice) - 1]
        console.print(f"[green]Interfaz seleccionada: {interfaz_seleccionada}[/green]")
        
        while True:
            # Escanea redes WiFi en la interfaz seleccionada
            networks = scan_wifi(interfaz_seleccionada)
            show_and_export_networks(networks)  # Muestra la información y la exporta a un archivo de texto

            # Selección de acción por parte del usuario
            choice = Prompt.ask(
                "\n[bold yellow]Selecciona el ID del SSID a copiar (ENTER para actualizar, q para salir):[/bold yellow]"
            )
            if choice.lower() == 'q':
                break
            elif choice.strip() == "":
                continue
            elif choice.isdigit() and int(choice) < len(networks):
                ssid = networks[int(choice)]['ESSID']
                pyperclip.copy(ssid)
                console.print(f"[green]SSID '{ssid}' copiado al portapapeles.[/green]")
                input("Presiona ENTER para continuar...")
            else:
                console.print("[red]ID no válido.[/red]")
            time.sleep(2)
    else:
        console.print("[red]Selección no válida.[/red]")

if __name__ == "__main__":
    main()
