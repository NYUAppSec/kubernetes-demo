#!/bin/bash
set -e

echo "=== Kubernetes Demo Setup ==="
echo ""

# Check prerequisites
command -v minikube >/dev/null 2>&1 || { echo "Error: minikube is not installed. See https://minikube.sigs.k8s.io/docs/start/"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl is not installed. See https://kubernetes.io/docs/tasks/tools/"; exit 1; }

# Start minikube if not running
if ! minikube status | grep -q "Running"; then
    echo "[1/4] Starting minikube..."
    minikube start
else
    echo "[1/4] minikube is already running."
fi

# Point Docker CLI to minikube's Docker daemon
echo "[2/4] Configuring Docker to use minikube's daemon..."
eval $(minikube docker-env)

# Build images inside minikube
echo "[3/4] Building container images..."
docker build -t k8s-demo-backend:latest ./backend
docker build -t k8s-demo-frontend:latest ./frontend

# Deploy to Kubernetes
echo "[4/4] Applying Kubernetes manifests..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

echo ""
echo "=== Waiting for pods to be ready ==="
kubectl wait --for=condition=ready pod -l app=backend --timeout=60s
kubectl wait --for=condition=ready pod -l app=frontend --timeout=60s

echo ""
echo "=== Demo is running! ==="
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""
echo "To open the frontend in your browser, run:"
echo "  minikube service frontend-service"
echo ""
echo "Or access it at: $(minikube ip):30080"
