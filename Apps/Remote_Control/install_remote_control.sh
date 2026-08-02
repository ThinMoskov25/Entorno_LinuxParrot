#!/bin/bash

# Instalación de xrdp
sudo apt update
sudo apt install -y xrdp

# Inicio del servicio xrdp
sudo systemctl start xrdp

# Habilitación del servicio xrdp para iniciar automáticamente al arrancar
sudo systemctl enable xrdp

# Configuración del firewall para permitir el tráfico entrante al puerto 3389 (utilizado por xrdp)
sudo ufw allow 3389

# Mensaje de confirmación
echo "xrdp se ha instalado y configurado correctamente. Ahora puedes conectarte a través de Escritorio Remoto."
