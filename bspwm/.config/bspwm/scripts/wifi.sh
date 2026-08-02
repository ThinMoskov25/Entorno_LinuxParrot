#!/bin/sh

# Detectar interfaz WiFi dinamicamente
INTERFACE=""
for iface in $(ls /sys/class/net/ 2>/dev/null); do
    # Verificar si es wireless (tiene directorio wireless o empieza con wl)
    if [ -d "/sys/class/net/$iface/wireless" ] || echo "$iface" | grep -qE "^wl"; then
        INTERFACE="$iface"
        break
    fi
done

# Si no hay interfaz wireless
if [ -z "$INTERFACE" ]; then
    echo "%{F#f28a8c}󰖪 %{F#ffffff}Disconnected %{u-}"
    exit 0
fi

# Obtener IP (usar ip, no ifconfig)
IP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)

if [ -z "$IP" ]; then
    echo "%{F#f28a8c}󰖪 %{F#ffffff}Disconnected %{u-}"
else
    echo "%{F#2495e7}󰖩 %{F#ffffff}$IP%{u-}"
fi
