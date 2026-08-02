#!/usr/bin/env bash

set -euo pipefail

KIRO_URL="https://prod.download.desktop.kiro.dev/releases/kiro-linux-amd64.deb"
TMP_DEB="/tmp/kiro.deb"

echo "[+] Descargando Kiro..."

wget -O "$TMP_DEB" "$KIRO_URL"

echo "[+] Instalando paquete..."

sudo dpkg -i "$TMP_DEB" || true

echo "[+] Resolviendo dependencias (sin actualizar repositorios)..."

sudo apt-get install -f -y

echo "[+] Limpiando..."

rm -f "$TMP_DEB"

echo
echo "======================================="
echo " Kiro instalado correctamente"
echo "======================================="
