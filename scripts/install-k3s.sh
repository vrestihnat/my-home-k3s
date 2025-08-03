#!/bin/bash

# Instalační script pro K3s s Traefik a cert-manager

set -e

echo "🚀 Instalace K3s clusteru..."

# Kontrola, zda K3s již není nainstalován
if command -v k3s &> /dev/null; then
    echo "⚠️  K3s je již nainstalován. Přeskakujem instalaci."
else
    # Instalace K3s s Traefik jako výchozí ingress controller
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
    
    # Čekání na spuštění K3s
    echo "⏳ Čekám na spuštění K3s..."
    sleep 30
fi

# Nastavení kubectl pro běžného uživatele
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Export KUBECONFIG pro aktuální session
export KUBECONFIG=~/.kube/config

echo "✅ K3s nainstalován!"

# Instalace Helm (pokud není nainstalován)
if ! command -v helm &> /dev/null; then
    echo "📦 Instaluji Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "🔧 Instaluji Traefik..."
# Instalace Traefik pomocí Helm
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Nejprve odstraníme případnou chybnou instalaci
helm uninstall traefik -n traefik-system 2>/dev/null || echo "Traefik nebyl nainstalován"

# Instalace Traefik s konfiguračním souborem
helm upgrade --install traefik traefik/traefik \
    --namespace traefik-system \
    --create-namespace \
    --values k3s/setup/traefik-values.yaml

echo "🔐 Instaluji cert-manager..."
# Instalace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

echo "⏳ Čekám na spuštění cert-manager..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

echo "🎯 Vytvářím ClusterIssuer pro Let's Encrypt..."
# Vytvoření ClusterIssuer pro automatické SSL certifikáty
kubectl apply -f k3s/setup/cluster-issuer.yaml

echo "🐳 Spouštím lokální Docker registry..."
# Spuštění lokálního Docker registry pro K3s
docker run -d --restart=unless-stopped -p 5000:5000 --name registry registry:2 || echo "Registry již běží"

echo "✅ K3s setup dokončen!"
echo ""
echo "📋 Užitečné příkazy:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  kubectl get ingress -A"
echo ""
echo "🌐 Traefik dashboard bude dostupný na: http://localhost:9000/dashboard/"
