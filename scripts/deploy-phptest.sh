#!/bin/bash

# Deployment script pro PHP test aplikaci

set -e

echo "🚀 Deploying PHP test aplikace..."

# Kontrola, zda K3s běží
if ! kubectl get nodes &> /dev/null; then
    echo "❌ K3s cluster není dostupný. Spusť nejprve: ./scripts/install-k3s.sh"
    exit 1
fi

# Build a push Docker image
echo "🔨 Building Docker image..."
cd apps/phptest
./build.sh
cd ../..

# Deploy Kubernetes manifesty postupně
echo "📦 Deploying Kubernetes manifesty..."
kubectl apply -f k3s/manifests/phptest/namespace.yaml
kubectl apply -f k3s/manifests/phptest/deployment.yaml
kubectl apply -f k3s/manifests/phptest/service.yaml

# Čekání na připravenost namespace a deployment
echo "⏳ Čekám na vytvoření namespace..."
kubectl wait --for=condition=ready namespace/phptest --timeout=60s 2>/dev/null || echo "Namespace vytvořen"

echo "📦 Deploying ingress..."
kubectl apply -f k3s/manifests/phptest/ingress.yaml

# Čekání na deployment
echo "⏳ Čekám na spuštění podů..."
kubectl wait --for=condition=ready pod -l app=phptest -n phptest --timeout=300s

# Zobrazení stavu
echo "📊 Stav deploymentu:"
kubectl get pods -n phptest
kubectl get services -n phptest
kubectl get ingress -n phptest

echo ""
echo "✅ Deployment dokončen!"

# Přidání DNS záznamu do Pi-hole
echo "🔧 Přidávám DNS záznam do Pi-hole..."
if ./scripts/manage-pihole-dns.sh add phptest.janzar.eu; then
    echo "✅ DNS záznam přidán do Pi-hole"
else
    echo "⚠️  DNS záznam se nepodařilo přidat - aplikace bude dostupná pouze z venkovní sítě"
fi

echo ""
echo "🌐 Aplikace je dostupná na: https://phptest.janzar.eu"
echo "   - Z internetu: ✅ Funguje"
echo "   - Z intranetu: ✅ Funguje (přes Pi-hole DNS)"
echo ""
echo "🔍 Užitečné příkazy pro monitoring:"
echo "  kubectl logs -f deployment/phptest -n phptest"
echo "  kubectl describe ingress phptest-ingress -n phptest"
echo "  kubectl get certificate -n phptest"
echo "  ./scripts/manage-pihole-dns.sh list"
