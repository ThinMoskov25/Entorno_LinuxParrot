#!/bin/sh

# Detectar interfaz de red activa dinamicamente
# Prioridad: ethernet con IP > cualquier interfaz con IP
INTERFACE=""

# Buscar primera interfaz ethernet con IP
for iface in $(ls /sys/class/net/ | grep -v lo); do
    if [ -d "/sys/class/net/$iface/device" ]; then
        IP=$(ip -4 addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
        if [ -n "$IP" ]; then
            INTERFACE="$iface"
            break
        fi
    fi
done

# Si no hay ethernet, buscar cualquier interfaz con IP
if [ -z "$INTERFACE" ]; then
    for iface in $(ls /sys/class/net/ | grep -v lo); do
        IP=$(ip -4 addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -1)
        if [ -n "$IP" ]; then
            INTERFACE="$iface"
            break
        fi
    done
fi

if [ -z "$IP" ]; then
    echo "%{F#f28a8c} %{F#ffffff}Disconnected %{u-}"
else
    echo "%{F#2495e7}󰈀 %{F#ffffff}$IP%{u-}"
fi
