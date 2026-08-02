#!/bin/bash

# Descargar el paquete de instalación de Visual Studio Code
wget -O vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868

# Instalar el paquete descargado
sudo dpkg -i vscode.deb

# Instalar dependencias faltantes
sudo apt install -f

# Limpiar el archivo descargado
rm vscode.deb

echo "Visual Studio Code se ha instalado correctamente."
