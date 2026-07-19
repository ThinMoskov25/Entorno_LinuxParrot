#!/bin/bash

# Interfaz a verificar
INTERFACE="tun0"

IFACE=$(ip -o link show | awk -v iface="$INTERFACE" '$2 ~ iface {print $2}' | tr -d ':')

if [ -n "$IFACE" ]; then
    IP=$(ip addr show "$INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    if [ -n "$IP" ]; then
        echo "%{F#1bbf3e}󰆧 %{F#ffffff}$IP%{u-}"
    fi
else
    echo "%{F#e06c75}󱐝 %{F#ffffff}Disconnected%{u-}"
fi
