#!/bin/bash
# Script para mostrar fecha, hora y estado de batería
# Llamado desde polybar o desde la función infbat en zsh

BAT_PATH="/sys/class/power_supply/BAT0"
AC_PATH="/sys/class/power_supply/ACAD"

# Batería
if [ -f "$BAT_PATH/capacity" ]; then
    capacity=$(cat "$BAT_PATH/capacity")
    status=$(cat "$BAT_PATH/status")

    # Icono según estado
    if [ "$status" = "Charging" ]; then
        icon=""
        state="Charging"
    elif [ "$status" = "Full" ]; then
        icon=""
        state="Full"
    else
        # Icono según porcentaje
        if [ "$capacity" -ge 90 ]; then
            icon=""
        elif [ "$capacity" -ge 60 ]; then
            icon=""
        elif [ "$capacity" -ge 40 ]; then
            icon=""
        elif [ "$capacity" -ge 20 ]; then
            icon=""
        else
            icon=""
        fi
        state="Discharging"
    fi

    bat_info="$icon $capacity% [$state]"
else
    bat_info="No battery"
fi

# Fecha y hora
datetime=$(date "+%a %d/%m/%Y  %H:%M:%S")

# Output
echo "$datetime | $bat_info"
