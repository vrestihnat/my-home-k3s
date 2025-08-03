# K3s Home Setup s automatickým SSL

Kompletní K3s řešení pro domácí server s automatickými SSL certifikáty pro subdomény janzar.eu.

## 🎯 Co tento projekt dělá

- **Automatické SSL certifikáty** z Let's Encrypt pro všechny subdomény
- **Traefik ingress controller** pro inteligentní směrování
- **Jednoduchý deployment** nových aplikací
- **Podpora subdomén** *.janzar.eu s automatickým HTTPS

## 📁 Struktura projektu

```
.
├── apps/                           # Aplikace
│   └── phptest/                   # Příklad PHP aplikace
│       ├── Dockerfile
│       ├── index.php
│       └── build.sh
├── k3s/                           # K3s konfigurace
│   ├── setup/                     # Instalační konfigurace
│   │   └── cluster-issuer.yaml    # Let's Encrypt konfigurace
│   └── manifests/                 # Kubernetes manifesty
│       └── phptest/               # PHP aplikace manifesty
├── scripts/                       # Pomocné skripty
│   ├── install-k3s.sh            # Instalace K3s clusteru
│   ├── deploy-phptest.sh          # Deploy PHP aplikace
│   ├── create-app-template.sh     # Vytvoření nové aplikace
│   └── status.sh                  # Stav clusteru
└── docs/                          # Dokumentace
    └── DEPLOYMENT_GUIDE.md        # Detailní návod
```

## 🚀 Quick Start

### 1. Instalace K3s clusteru
```bash
./scripts/install-k3s.sh
```

### 2. Deploy PHP test aplikace
```bash
./scripts/deploy-phptest.sh
```

### 3. Kontrola stavu
```bash
./scripts/status.sh
```

Aplikace bude dostupná na: **https://phptest.janzar.eu**

## 🔧 Jak to funguje

### Architektura
```
Internet (*.janzar.eu:443/80)
    ↓
Router/Firewall (port forwarding)
    ↓
K3s Node (tento stroj)
    ↓
Traefik Ingress Controller
    ↓
Kubernetes Services
    ↓
Application Pods
```

### Komponenty
1. **K3s** - Lightweight Kubernetes
2. **Traefik** - Ingress controller + load balancer
3. **cert-manager** - Automatické SSL z Let's Encrypt
4. **Docker Registry** - Lokální registry pro images

## 📱 Přidání nové aplikace

### Rychlý způsob (template)
```bash
./scripts/create-app-template.sh myapp myapp.janzar.eu
./scripts/deploy-myapp.sh
```

### Manuální způsob
1. Vytvoř aplikaci v `apps/myapp/`
2. Vytvoř manifesty v `k3s/manifests/myapp/`
3. Deploy: `kubectl apply -f k3s/manifests/myapp/`

## 📊 Monitoring

```bash
# Stav clusteru
./scripts/status.sh

# Logy aplikace
kubectl logs -f deployment/phptest -n phptest

# SSL certifikáty
kubectl get certificate -A

# Traefik dashboard
kubectl port-forward -n traefik-system deployment/traefik 9000:9000
# Otevři: http://localhost:9000/dashboard/
```

## 📚 Dokumentace

- [Detailní deployment guide](docs/DEPLOYMENT_GUIDE.md)
- [Troubleshooting](docs/DEPLOYMENT_GUIDE.md#časté-problémy)

## ⚡ Požadavky

- Ubuntu/Debian server
- Docker nainstalován
- Porty 80 a 443 přesměrované na tento stroj
- DNS *.janzar.eu směřující na veřejnou IP
