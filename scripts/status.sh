#!/bin/bash

# Script pro zobrazení stavu K3s clusteru a aplikací

echo "🔍 K3s Cluster Status"
echo "===================="

# Kontrola K3s
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl není nainstalován"
    exit 1
fi

if ! kubectl get nodes &> /dev/null; then
    echo "❌ K3s cluster není dostupný"
    exit 1
fi

echo "✅ K3s cluster je dostupný"
echo ""

# Stav nodů
echo "📊 Nodes:"
kubectl get nodes -o wide

echo ""
echo "📦 System Pods:"
kubectl get pods -n kube-system

echo ""
echo "🔧 Traefik:"
kubectl get pods -n traefik-system

echo ""
echo "🔐 Cert-manager:"
kubectl get pods -n cert-manager

echo ""
echo "🌐 Ingress Controllers:"
kubectl get ingress -A

echo ""
echo "🔒 SSL Certificates:"
kubectl get certificate -A

echo ""
echo "📱 Applications:"
kubectl get pods -A | grep -v "kube-system\|traefik-system\|cert-manager"

echo ""
echo "🐳 Docker Registry:"
if docker ps | grep -q registry; then
    echo "✅ Registry běží na portu 5000"
else
    echo "❌ Registry neběží"
fi

echo ""
echo "💾 Disk Usage:"
df -h / | tail -1

echo ""
echo "🔧 Užitečné příkazy:"
echo "  kubectl get pods -A                    # Všechny pody"
echo "  kubectl logs -f deployment/APP -n NS   # Logy aplikace"
echo "  kubectl describe ingress -A            # Detail ingress"
echo "  kubectl get certificate -A             # SSL certifikáty"
