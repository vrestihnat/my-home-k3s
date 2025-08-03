#!/bin/bash

# Build script pro PHP test aplikaci

set -e

IMAGE_NAME="phptest"
IMAGE_TAG="latest"
REGISTRY="localhost:5000"  # Lokální registry pro K3s

echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "🏷️  Tagging image for registry..."
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "📤 Pushing to registry..."
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo "✅ Build complete!"
echo "Image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
