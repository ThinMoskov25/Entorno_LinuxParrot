#!/bin/bash

# Directorio de configuración de Visual Studio Code
CONFIG_DIR="$HOME/.config/Code/User"

# Verificar si el directorio de configuración existe
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: No se encontró el directorio de configuración de Visual Studio Code."
    exit 1
fi

# Agregar la configuración de idioma a settings.json
echo '{ "locale": "es" }' > "$CONFIG_DIR/settings.json"

echo "El idioma de Visual Studio Code se ha cambiado a español."
