#!/bin/bash
# Script de hardening básico con UFW para Parrot Security
# Uso: sudo bash hardening_ufw.sh

set -e

echo "============================================"
echo "  Hardening UFW - Parrot Security"
echo "============================================"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script requiere sudo. Ejecuta: sudo bash $0"
    exit 1
fi

# Reset de reglas previas
echo "[+] Reseteando reglas UFW anteriores..."
ufw --force reset

# Política por defecto: denegar todo entrante, permitir todo saliente
echo "[+] Configurando políticas por defecto..."
ufw default deny incoming
ufw default allow outgoing

# Permitir conexiones locales (loopback)
echo "[+] Permitiendo tráfico local (loopback)..."
ufw allow in on lo

# Permitir SSH (por si usas acceso remoto con AnyDesk/SSH)
echo "[+] Permitiendo SSH (puerto 22)..."
ufw allow 22/tcp comment 'SSH'

# Permitir AnyDesk (usa puertos 7070 y rango 50001-50003)
echo "[+] Permitiendo AnyDesk..."
ufw allow 7070/tcp comment 'AnyDesk'

# Permitir VPN (OpenVPN para HTB y otros)
echo "[+] Permitiendo tráfico VPN (OpenVPN, WireGuard)..."
ufw allow 1194/udp comment 'OpenVPN'
ufw allow 51820/udp comment 'WireGuard'

# Permitir tráfico DNS saliente (ya permitido por default allow outgoing)
# Bloquear pings entrantes (anti-reconocimiento)
echo "[+] Bloqueando pings entrantes (ICMP)..."
sed -i 's/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/-A ufw-before-input -p icmp --icmp-type echo-request -j DROP/' /etc/ufw/before.rules 2>/dev/null || true

# Habilitar logging nivel bajo (para no llenar disco)
echo "[+] Habilitando logging nivel bajo..."
ufw logging low

# Activar UFW
echo "[+] Activando UFW..."
ufw --force enable

# Mostrar estado
echo ""
echo "============================================"
echo "  Estado final de UFW:"
echo "============================================"
ufw status verbose

echo ""
echo "[✓] Hardening completado."
echo ""
echo "Notas:"
echo "  - Entrante: DENEGADO por defecto"
echo "  - Saliente: PERMITIDO por defecto"
echo "  - SSH (22), AnyDesk (7070), VPN (1194, 51820) permitidos"
echo "  - Pings entrantes bloqueados"
echo ""
echo "  Para agregar más reglas: sudo ufw allow <puerto>/<protocolo>"
echo "  Para desactivar temporalmente: sudo ufw disable"
echo "  Para ver estado: sudo ufw status numbered"
