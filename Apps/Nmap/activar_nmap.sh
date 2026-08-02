#!/bin/bash

echo "[+] Corrigiendo claves GPG faltantes..."

# Claves GPG comunes
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7A8286AF0E81EE4A
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B7B3B788A8D3785C
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A2FB21D5A8772835

echo "[+] Actualizando sistema..."
sudo apt update

echo "[+] Instalando dependencias para compilar LPeg..."
sudo apt install -y build-essential lua5.4 liblua5.4-dev wget unzip

echo "[+] Descargando LPeg desde GitHub (ZIP)..."
wget https://github.com/lua/lpeg/archive/refs/heads/master.zip -O lpeg.zip

echo "[+] Descomprimiendo..."
unzip lpeg.zip
cd lpeg-master || { echo "[!] No se pudo entrar al directorio lpeg-master"; exit 1; }

echo "[+] Compilando LPeg..."
make || { echo "[!] Error al compilar LPeg"; exit 1; }

echo "[+] Instalando LPeg..."
sudo make install

echo "[✓] Listo. ¡LPeg instalado y Nmap debería funcionar!"
