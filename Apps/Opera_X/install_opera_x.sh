#!/bin/bash

# Descargar e instalar la clave GPG de Opera
wget -qO- https://deb.opera.com/archive.key | sudo apt-key add -

# Agregar el repositorio de Opera al sistema
echo "deb https://deb.opera.com/opera-stable/ stable non-free" | sudo tee /etc/apt/sources.list.d/opera.list

# Actualizar la lista de paquetes
sudo apt update

# Instalar Opera
sudo apt install opera-stable -y
