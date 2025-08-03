#!/bin/bash

# Script pro nastavení lokálního DNS pro intranet přístup

LOCAL_IP="192.168.17.26"
DOMAINS=("phptest.janzar.eu")

echo "🔧 Nastavuji lokální DNS pro intranet přístup..."

# Backup původního /etc/hosts
if [ ! -f /etc/hosts.backup ]; then
    sudo cp /etc/hosts /etc/hosts.backup
    echo "✅ Vytvořen backup /etc/hosts.backup"
fi

# Odstranění starých záznamů
echo "🧹 Odstraňuji staré záznamy..."
for domain in "${DOMAINS[@]}"; do
    sudo sed -i "/$domain/d" /etc/hosts
done

# Přidání nových záznamů
echo "➕ Přidávám lokální DNS záznamy..."
echo "" | sudo tee -a /etc/hosts
echo "# K3s lokální DNS záznamy" | sudo tee -a /etc/hosts
for domain in "${DOMAINS[@]}"; do
    echo "$LOCAL_IP $domain" | sudo tee -a /etc/hosts
    echo "✅ Přidán: $domain → $LOCAL_IP"
done

echo ""
echo "🎯 Lokální DNS nastaven!"
echo "📱 Pro ostatní zařízení v síti:"
echo "   - Přidej do /etc/hosts (Linux/Mac)"
echo "   - Přidej do C:\\Windows\\System32\\drivers\\etc\\hosts (Windows)"
echo "   - Nebo nastav na routeru lokální DNS"
echo ""
echo "🔄 Pro obnovení původního stavu:"
echo "   sudo cp /etc/hosts.backup /etc/hosts"
