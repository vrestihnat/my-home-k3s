# K3s Deployment Guide

## Jak celý systém funguje

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

1. **K3s** - Lightweight Kubernetes distribuce
2. **Traefik** - Ingress controller pro směrování a load balancing
3. **cert-manager** - Automatické SSL certifikáty z Let's Encrypt
4. **Docker Registry** - Lokální registry pro Docker images

## Instalace a první spuštění

### 1. Instalace K3s clusteru
```bash
./scripts/install-k3s.sh
```

Tento script:
- Nainstaluje K3s
- Nastaví Traefik jako ingress controller
- Nainstaluje cert-manager pro SSL
- Vytvoří ClusterIssuer pro Let's Encrypt
- Spustí lokální Docker registry

### 2. Deploy PHP test aplikace
```bash
./scripts/deploy-phptest.sh
```

## Jak přidat novou aplikaci

### 1. Vytvoř Docker aplikaci
```
apps/
└── my-app/
    ├── Dockerfile
    ├── build.sh
    └── [aplikační soubory]
```

### 2. Vytvoř Kubernetes manifesty
```
k3s/manifests/my-app/
├── namespace.yaml
├── deployment.yaml
├── service.yaml
└── ingress.yaml
```

### 3. Použij template pro ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - my-app.janzar.eu
    secretName: my-app-tls
  rules:
  - host: my-app.janzar.eu
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

### 4. Deploy
```bash
kubectl apply -f k3s/manifests/my-app/
```

## Monitoring a troubleshooting

### Užitečné příkazy
```bash
# Stav clusteru
kubectl get nodes
kubectl get pods -A

# Stav aplikace
kubectl get pods -n my-app
kubectl logs -f deployment/my-app -n my-app

# Stav ingress a SSL
kubectl get ingress -A
kubectl get certificate -A
kubectl describe certificate my-app-tls -n my-app

# Traefik dashboard
kubectl port-forward -n traefik-system deployment/traefik 9000:9000
# Pak otevři: http://localhost:9000/dashboard/
```

### Časté problémy

1. **SSL certifikát se nevygeneruje**
   - Zkontroluj DNS: `nslookup my-app.janzar.eu`
   - Zkontroluj cert-manager: `kubectl logs -n cert-manager deployment/cert-manager`

2. **Aplikace není dostupná**
   - Zkontroluj pody: `kubectl get pods -n my-app`
   - Zkontroluj service: `kubectl get svc -n my-app`
   - Zkontroluj ingress: `kubectl describe ingress -n my-app`

3. **Docker image se nenačte**
   - Zkontroluj registry: `docker ps | grep registry`
   - Rebuild image: `cd apps/my-app && ./build.sh`
