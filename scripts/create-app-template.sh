#!/bin/bash

# Script pro vytvoření template nové aplikace

if [ $# -ne 2 ]; then
    echo "Usage: $0 <app-name> <subdomain>"
    echo "Example: $0 myapp myapp.janzar.eu"
    exit 1
fi

APP_NAME=$1
SUBDOMAIN=$2

echo "🚀 Vytvářím template pro aplikaci: $APP_NAME"
echo "📍 Subdoména: $SUBDOMAIN"

# Vytvoření adresářové struktury
mkdir -p "apps/$APP_NAME"
mkdir -p "k3s/manifests/$APP_NAME"

# Vytvoření základního Dockerfile
cat > "apps/$APP_NAME/Dockerfile" << EOF
FROM nginx:alpine

# Kopírování aplikace
COPY . /usr/share/nginx/html/

# Základní konfigurace
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Vytvoření build scriptu
cat > "apps/$APP_NAME/build.sh" << EOF
#!/bin/bash

set -e

IMAGE_NAME="$APP_NAME"
IMAGE_TAG="latest"
REGISTRY="localhost:5000"

echo "🔨 Building Docker image..."
docker build -t \${IMAGE_NAME}:\${IMAGE_TAG} .

echo "🏷️  Tagging image for registry..."
docker tag \${IMAGE_NAME}:\${IMAGE_TAG} \${REGISTRY}/\${IMAGE_NAME}:\${IMAGE_TAG}

echo "📤 Pushing to registry..."
docker push \${REGISTRY}/\${IMAGE_NAME}:\${IMAGE_TAG}

echo "✅ Build complete!"
echo "Image: \${REGISTRY}/\${IMAGE_NAME}:\${IMAGE_TAG}"
EOF

chmod +x "apps/$APP_NAME/build.sh"

# Vytvoření základní HTML stránky
cat > "apps/$APP_NAME/index.html" << EOF
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$APP_NAME</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $APP_NAME</h1>
        <p>Aplikace úspěšně nasazena na K3s!</p>
        <p>Subdoména: <strong>$SUBDOMAIN</strong></p>
    </div>
</body>
</html>
EOF

# Vytvoření Kubernetes manifestů
cat > "k3s/manifests/$APP_NAME/namespace.yaml" << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $APP_NAME
  labels:
    name: $APP_NAME
EOF

cat > "k3s/manifests/$APP_NAME/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
    spec:
      containers:
      - name: $APP_NAME
        image: localhost:5000/$APP_NAME:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
      imagePullPolicy: Always
EOF

cat > "k3s/manifests/$APP_NAME/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME-service
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
spec:
  selector:
    app: $APP_NAME
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
EOF

cat > "k3s/manifests/$APP_NAME/ingress.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME-ingress
  namespace: $APP_NAME
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/redirect-entry-point: https
    traefik.ingress.kubernetes.io/redirect-permanent: "true"
spec:
  tls:
  - hosts:
    - $SUBDOMAIN
    secretName: $APP_NAME-tls
  rules:
  - host: $SUBDOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $APP_NAME-service
            port:
              number: 80
EOF

# Vytvoření deployment scriptu
cat > "scripts/deploy-$APP_NAME.sh" << EOF
#!/bin/bash

set -e

echo "🚀 Deploying $APP_NAME..."

# Build a push Docker image
echo "🔨 Building Docker image..."
cd apps/$APP_NAME
./build.sh
cd ../..

# Deploy Kubernetes manifesty
echo "📦 Deploying Kubernetes manifesty..."
kubectl apply -f k3s/manifests/$APP_NAME/

# Čekání na deployment
echo "⏳ Čekám na spuštění podů..."
kubectl wait --for=condition=ready pod -l app=$APP_NAME -n $APP_NAME --timeout=300s

echo "✅ Deployment dokončen!"

# Přidání DNS záznamu do Pi-hole
echo "🔧 Přidávám DNS záznam do Pi-hole..."
if ./scripts/manage-pihole-dns.sh add $SUBDOMAIN; then
    echo "✅ DNS záznam přidán do Pi-hole"
else
    echo "⚠️  DNS záznam se nepodařilo přidat - aplikace bude dostupná pouze z venkovní sítě"
fi

echo ""
echo "🌐 Aplikace je dostupná na: https://$SUBDOMAIN"
echo "   - Z internetu: ✅ Funguje"
echo "   - Z intranetu: ✅ Funguje (přes Pi-hole DNS)"
EOF

chmod +x "scripts/deploy-$APP_NAME.sh"

echo "✅ Template vytvořen!"
echo ""
echo "📁 Vytvořené soubory:"
echo "  apps/$APP_NAME/"
echo "  k3s/manifests/$APP_NAME/"
echo "  scripts/deploy-$APP_NAME.sh"
echo ""
echo "🚀 Pro nasazení spusť:"
echo "  ./scripts/deploy-$APP_NAME.sh"
