#!/bin/bash
# Script de instalación de dotfiles con stow
# Uso: ./install.sh

set -e

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

# Verificar que stow esté instalado
if ! command -v stow &>/dev/null; then
    echo "[!] stow no está instalado. Instalando..."
    sudo apt install stow -y
fi

# Backup de archivos existentes que podrían conflictar
echo "[+] Creando backup de archivos existentes..."
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in .zshrc .bashrc .profile .p10k.zsh; do
    [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ] && mv "$HOME/$file" "$BACKUP_DIR/"
done

# Hacer stow de cada paquete
PACKAGES=(zsh bash bspwm sxhkd kitty picom polybar rofi nvim neofetch)

echo "[+] Enlazando dotfiles..."
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        stow -v -R "$pkg" -t "$HOME"
        echo "  [✓] $pkg"
    fi
done

echo ""
echo "[✓] Dotfiles enlazados correctamente."
echo "[✓] Backup guardado en: $BACKUP_DIR"
echo ""
echo "Para agregar cambios al repo:"
echo "  cd ~/dotfiles && git add -A && git commit -m 'actualizar configs'"
