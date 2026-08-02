#!/bin/bash

# Script para instalar 7zip en Linux

echo "🔍 Detectando distribución de Linux..."

# Detectar el sistema de paquetes
if command -v apt &> /dev/null; then
    echo "📦 Sistema basado en Debian/Ubuntu detectado."
    echo "⏳ Instalando p7zip-full..."
    sudo apt update
    sudo apt install -y p7zip-full

elif command -v dnf &> /dev/null; then
    echo "📦 Sistema basado en Fedora detectado."
    echo "⏳ Instalando p7zip..."
    sudo dnf install -y p7zip p7zip-plugins

elif command -v yum &> /dev/null; then
    echo "📦 Sistema basado en RHEL/CentOS detectado."
    echo "⏳ Instalando p7zip..."
    sudo yum install -y p7zip p7zip-plugins

elif command -v pacman &> /dev/null; then
    echo "📦 Sistema basado en Arch Linux detectado."
    echo "⏳ Instalando p7zip..."
    sudo pacman -Sy --noconfirm p7zip

else
    echo "❌ No se pudo detectar el sistema de paquetes. Instala 7zip manualmente."
    exit 1
fi

echo "✅ Instalación completada. Puedes usar el comando '7z' ahora."
