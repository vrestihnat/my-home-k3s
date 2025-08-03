#!/bin/bash

# Script pro správu DNS záznamů v Pi-hole custom.list

# Konfigurace
PIHOLE_HOST="192.168.17.7"
PIHOLE_USER="root"
PIHOLE_CUSTOM_LIST="/root/docker/pihole/etc-pihole/custom.list"
LOCAL_K3S_IP="192.168.17.26"

# Funkce pro zobrazení nápovědy
show_help() {
    echo "🔧 Pi-hole DNS Manager pro K3s"
    echo ""
    echo "Usage: $0 <command> [domain]"
    echo ""
    echo "Commands:"
    echo "  add <domain>     - Přidá DNS záznam pro doménu"
    echo "  remove <domain>  - Odstraní DNS záznam pro doménu"
    echo "  list             - Zobrazí všechny K3s DNS záznamy"
    echo "  sync             - Synchronizuje všechny aplikace z K3s"
    echo "  backup           - Vytvoří backup custom.list"
    echo "  restore          - Obnoví backup custom.list"
    echo ""
    echo "Examples:"
    echo "  $0 add phptest.janzar.eu"
    echo "  $0 remove phptest.janzar.eu"
    echo "  $0 sync"
}

# Funkce pro kontrolu SSH připojení
check_ssh() {
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $PIHOLE_USER@$PIHOLE_HOST exit 2>/dev/null; then
        echo "❌ Nelze se připojit k Pi-hole serveru $PIHOLE_HOST"
        echo "💡 Zkontroluj:"
        echo "   - SSH klíče: ssh-copy-id $PIHOLE_USER@$PIHOLE_HOST"
        echo "   - Síťové připojení"
        echo "   - Pi-hole server běží"
        exit 1
    fi
}

# Funkce pro přidání DNS záznamu
add_dns_record() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        echo "❌ Chybí doména"
        echo "Usage: $0 add <domain>"
        exit 1
    fi
    
    echo "➕ Přidávám DNS záznam: $domain → $LOCAL_K3S_IP"
    
    # Odstranění existujícího záznamu (pokud existuje)
    ssh $PIHOLE_USER@$PIHOLE_HOST "sed -i '/$domain/d' $PIHOLE_CUSTOM_LIST"
    
    # Přidání nového záznamu
    ssh $PIHOLE_USER@$PIHOLE_HOST "echo '$LOCAL_K3S_IP $domain' >> $PIHOLE_CUSTOM_LIST"
    
    # Restart Pi-hole DNS
    ssh $PIHOLE_USER@$PIHOLE_HOST "docker exec pihole pihole restartdns"
    
    echo "✅ DNS záznam přidán a Pi-hole restartován"
}

# Funkce pro odstranění DNS záznamu
remove_dns_record() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        echo "❌ Chybí doména"
        echo "Usage: $0 remove <domain>"
        exit 1
    fi
    
    echo "🗑️  Odstraňuji DNS záznam: $domain"
    
    # Odstranění záznamu
    ssh $PIHOLE_USER@$PIHOLE_HOST "sed -i '/$domain/d' $PIHOLE_CUSTOM_LIST"
    
    # Restart Pi-hole DNS
    ssh $PIHOLE_USER@$PIHOLE_HOST "docker exec pihole pihole restartdns"
    
    echo "✅ DNS záznam odstraněn a Pi-hole restartován"
}

# Funkce pro zobrazení K3s DNS záznamů
list_dns_records() {
    echo "📋 K3s DNS záznamy v Pi-hole:"
    echo ""
    
    # Zobrazení záznamů obsahujících K3s IP
    ssh $PIHOLE_USER@$PIHOLE_HOST "grep '$LOCAL_K3S_IP' $PIHOLE_CUSTOM_LIST" || echo "Žádné K3s DNS záznamy nenalezeny"
}

# Funkce pro synchronizaci všech K3s aplikací
sync_k3s_apps() {
    echo "🔄 Synchronizuji K3s aplikace s Pi-hole DNS..."
    
    # Kontrola kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl není dostupný"
        exit 1
    fi
    
    # Export KUBECONFIG
    export KUBECONFIG=~/.kube/config
    
    # Získání všech ingress hostů
    local hosts=$(kubectl get ingress -A -o jsonpath='{range .items[*]}{.spec.rules[*].host}{"\n"}{end}' | sort | uniq)
    
    if [ -z "$hosts" ]; then
        echo "❌ Žádné ingress hosty nenalezeny"
        exit 1
    fi
    
    echo "🔍 Nalezené K3s aplikace:"
    echo "$hosts"
    echo ""
    
    # Přidání každého hostu do Pi-hole
    while IFS= read -r host; do
        if [ ! -z "$host" ]; then
            echo "➕ Přidávám: $host"
            add_dns_record "$host"
        fi
    done <<< "$hosts"
    
    echo "✅ Synchronizace dokončena"
}

# Funkce pro backup
backup_custom_list() {
    local backup_file="custom.list.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo "💾 Vytvářím backup Pi-hole custom.list..."
    
    ssh $PIHOLE_USER@$PIHOLE_HOST "cp $PIHOLE_CUSTOM_LIST $PIHOLE_CUSTOM_LIST.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Stažení backup na lokální stroj
    scp $PIHOLE_USER@$PIHOLE_HOST:$PIHOLE_CUSTOM_LIST ./backups/$backup_file 2>/dev/null || {
        mkdir -p backups
        scp $PIHOLE_USER@$PIHOLE_HOST:$PIHOLE_CUSTOM_LIST ./backups/$backup_file
    }
    
    echo "✅ Backup vytvořen: ./backups/$backup_file"
}

# Funkce pro restore
restore_custom_list() {
    echo "🔄 Dostupné backupy:"
    ls -la backups/custom.list.backup.* 2>/dev/null || {
        echo "❌ Žádné backupy nenalezeny"
        exit 1
    }
    
    echo ""
    read -p "Zadej název backup souboru: " backup_file
    
    if [ ! -f "backups/$backup_file" ]; then
        echo "❌ Backup soubor nenalezen"
        exit 1
    fi
    
    echo "⚠️  Obnovuji backup: $backup_file"
    read -p "Pokračovat? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        scp backups/$backup_file $PIHOLE_USER@$PIHOLE_HOST:$PIHOLE_CUSTOM_LIST
        ssh $PIHOLE_USER@$PIHOLE_HOST "docker exec pihole pihole restartdns"
        echo "✅ Backup obnoven a Pi-hole restartován"
    else
        echo "❌ Restore zrušen"
    fi
}

# Hlavní logika
case "$1" in
    "add")
        check_ssh
        add_dns_record "$2"
        ;;
    "remove")
        check_ssh
        remove_dns_record "$2"
        ;;
    "list")
        check_ssh
        list_dns_records
        ;;
    "sync")
        check_ssh
        sync_k3s_apps
        ;;
    "backup")
        check_ssh
        backup_custom_list
        ;;
    "restore")
        check_ssh
        restore_custom_list
        ;;
    *)
        show_help
        exit 1
        ;;
esac
