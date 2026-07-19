#!/bin/sh

# Interfaz a verificar
INTERFACE="wlo1"

# Obtener la dirección IP de la interfaz especificada
IP=$( /usr/sbin/ifconfig $INTERFACE | grep "inet " | awk '{print $2}' )

# Si la IP está vacía, significa que la interfaz no tiene una IP asignada
if [ -z "$IP" ]; then
    # Mostrar un icono de "Disconnected" en color rojo suave
    echo "%{F#f28a8c}󰖪 %{F#ffffff}Disconnected %{u-}"
else
    # Si hay IP, mostrarla en el formato adecuado
    echo "%{F#2495e7}󰖩 %{F#ffffff}$IP%{u-}"
fi
