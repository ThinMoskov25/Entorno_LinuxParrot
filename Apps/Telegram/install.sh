#!/bin/bash

# Verificar si el usuario es root
if [ "$(id -u)" != "0" ]; then
  echo "Este script debe ejecutarse como root" 1>&2
  exit 1
fi

# Actualizar la lista de paquetes
apt update

# Instalar Telegram
apt install telegram-desktop -y

echo "Telegram se ha instalado correctamente."
