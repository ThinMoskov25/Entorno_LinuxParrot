#!/bin/bash

# Leer la línea completa
read ip_address machine_name < "$HOME/.config/bin/target"

# Verificar si ambos valores existen
if [ "$ip_address" ] && [ "$machine_name" ]; then
    echo "%{F#e51d0b}󰓾 %{F#ffffff}$ip_address%{u-} - $machine_name"
else
    echo "%{F#f28a8c}󰓾 %{u-}%{F#ffffff} No target"
fi








