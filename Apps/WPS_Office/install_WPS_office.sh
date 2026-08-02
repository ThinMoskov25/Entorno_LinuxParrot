#!/bin/bash

# Este script instala WPS Office en Parrot OS

# Descarga el paquete de instalación de WPS Office
wget -O wps-office.deb https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/10702/wps-office_11.1.0.10702.XA_amd64.deb

# Instala el paquete descargado
sudo dpkg -i wps-office.deb

# Instala las dependencias que puedan faltar
sudo apt install -f

# Limpia el archivo descargado
rm wps-office.deb
